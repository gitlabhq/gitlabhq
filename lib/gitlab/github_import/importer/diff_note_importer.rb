# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class DiffNoteImporter
        include ::Import::PlaceholderReferences::Pusher
        include Gitlab::Utils::StrongMemoize

        DiffNoteCreationError = Class.new(ActiveRecord::RecordInvalid)

        attr_reader :imported_note_id

        # note - An instance of `Gitlab::GithubImport::Representation::DiffNote`
        # project - An instance of `Project`
        # client - An instance of `Gitlab::GithubImport::Client`
        def initialize(note, project, client)
          @note = note
          @project = project
          @client = client
        end

        def execute
          return if merge_request_id.blank?

          note.merge_request = merge_request

          # Diff notes with suggestions are imported with DiffNote, which is
          # slower to import than LegacyDiffNote. Importing DiffNote is slower
          # because it cannot use the BulkImporting strategy, which skips
          # callbacks and validations. For this reason, notes that don't have
          # suggestions are still imported with LegacyDiffNote
          if note.contains_suggestion?
            import_with_diff_note
          else
            import_with_legacy_diff_note
          end
        rescue ::DiffNote::NoteDiffFileCreationError, DiffNoteCreationError => e
          Logger.warn(message: e.message, 'error.class': e.class.name)

          import_with_legacy_diff_note
        end

        # Returns the GitLab attributes shared by both note types, so a sync can reuse them.
        def import_attributes
          author_id, author_found = user_finder.author_id_for(note)

          {
            noteable_type: note.noteable_type,
            noteable_id: merge_request_id,
            project_id: project.id,
            author_id: author_id,
            note: MarkdownText.format(note.note, note.author, author_found, project: project, client: client),
            discussion_id: note.discussion_id,
            system: false,
            created_at: note.created_at,
            updated_at: note.updated_at,
            imported_from: ::Import::HasImportSource::IMPORT_SOURCES[:github]
          }
        end
        strong_memoize_attr :import_attributes

        def find_noteable_id
          merge_request_id
        end

        private

        attr_reader :note, :project, :client

        # rubocop:disable Gitlab/BulkInsert
        def import_with_legacy_diff_note
          log_diff_note_creation('LegacyDiffNote')
          # It's possible that during an import we'll insert tens of thousands
          # of diff notes. If we were to use the Note/LegacyDiffNote model here
          # we'd also have to run additional queries for both validations and
          # callbacks, putting a lot of pressure on the database.
          #
          # To work around this we're using bulk_insert with a single row. This
          # allows us to efficiently insert data (even if it's just 1 row)
          # without having to use all sorts of hacks to disable callbacks.
          attributes = import_attributes.merge(
            type: 'LegacyDiffNote',
            commit_id: note.original_commit_id,
            line_code: note.line_code,
            st_diff: note.diff_hash.to_yaml
          )

          diff_note = LegacyDiffNote.new(attributes.merge(importing: true))
          diff_note.validate!

          ids = ApplicationRecord.legacy_bulk_insert(LegacyDiffNote.table_name, [attributes], return_ids: true)
          @imported_note_id = ids.first

          push_references_by_ids(project, ids, LegacyDiffNote, :author_id, note[:author]&.id)
        end
        # rubocop:enabled Gitlab/BulkInsert

        def import_with_diff_note
          log_diff_note_creation('DiffNote')

          record = ::Import::Github::Notes::CreateService.new(project, author, import_attributes.merge(
            type: 'DiffNote',
            commit_id: note.original_commit_id,
            position: note.diff_position
          )).execute(importing: true)

          raise DiffNoteCreationError, record unless record.persisted?

          @imported_note_id = record.id
          push_reference(project, record, :author_id, note.author&.id)
        end

        def author
          @author ||= User.find(import_attributes[:author_id])
        end

        def merge_request
          @merge_request ||= MergeRequest.find(merge_request_id)
        end

        # Returns the ID of the merge request this note belongs to.
        def merge_request_id
          @merge_request_id ||= GithubImport::IssuableFinder.new(project, note).database_id
        end

        def user_finder
          @user_finder ||= GithubImport::UserFinder.new(project, client)
        end

        def log_diff_note_creation(model)
          Logger.info(
            project_id: project.id,
            importer: self.class.name,
            external_identifiers: note.github_identifiers,
            model: model
          )
        end
      end
    end
  end
end

Gitlab::GithubImport::Importer::DiffNoteImporter.prepend_mod
