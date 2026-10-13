# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class NoteImporter
        include Gitlab::Import::UsernameMentionRewriter
        include ::Import::PlaceholderReferences::Pusher
        include Gitlab::Utils::StrongMemoize

        attr_reader :note, :project, :client, :user_finder, :imported_note_id

        # note - An instance of `Gitlab::GithubImport::Representation::Note`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(note, project, client)
          @note = note
          @project = project
          @client = client
          @user_finder = GithubImport::UserFinder.new(project, client)
        end

        def execute
          attributes = import_attributes

          Note.new(attributes.merge(importing: true)).validate!

          # We're using bulk_insert here so we can bypass any callbacks.
          # Running these would result in a lot of unnecessary SQL
          # queries being executed when importing large projects.
          # Note: if you're going to replace `legacy_bulk_insert` with something that trigger callback
          # to generate HTML version - you also need to regenerate it in
          # Gitlab::GithubImport::Importer::NoteAttachmentsImporter.
          ids = ApplicationRecord.legacy_bulk_insert(Note.table_name, [attributes], return_ids: true) # rubocop:disable Gitlab/BulkInsert
          @imported_note_id = ids.first

          push_references_by_ids(project, ids, Note, :author_id, note[:author]&.id)
        end

        # Returns the GitLab attributes for this representation, so a sync can reuse them.
        def import_attributes
          noteable_id = find_noteable_id

          raise Exceptions::NoteableNotFound, 'Error to find noteable_id for note' unless noteable_id

          author_id, author_found = user_finder.author_id_for(note)

          {
            noteable_type: note.noteable_type,
            noteable_id: noteable_id,
            project_id: project.id,
            author_id: author_id,
            note: note_body(author_found),
            discussion_id: note.discussion_id,
            system: false,
            created_at: note.created_at,
            updated_at: note.updated_at,
            imported_from: ::Import::HasImportSource::IMPORT_SOURCES[:github]
          }
        end
        strong_memoize_attr :import_attributes

        # Returns the ID of the issue or merge request to create the note for.
        def find_noteable_id
          GithubImport::IssuableFinder.new(project, note).database_id
        end

        def push_placeholder_references(imported_note)
          push_reference(project, imported_note, :author_id, note[:author]&.id)
        end

        private

        def note_body(author_found)
          MarkdownText.format(note.note, note.author, author_found, project: project, client: client)
        end
      end
    end
  end
end
