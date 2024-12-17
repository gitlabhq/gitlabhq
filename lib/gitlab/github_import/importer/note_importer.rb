# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class NoteImporter
        include Gitlab::Import::UsernameMentionRewriter
        include Gitlab::GithubImport::PushPlaceholderReferences

        attr_reader :note, :project, :client, :user_finder, :mapper

        # note - An instance of `Gitlab::GithubImport::Representation::Note`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(note, project, client)
          @note = note
          @project = project
          @client = client
          @user_finder = GithubImport::UserFinder.new(project, client)
          @mapper = Gitlab::GithubImport::ContributionsMapper.new(project)
        end

        def execute
          noteable_id = find_noteable_id

          raise Exceptions::NoteableNotFound, 'Error to find noteable_id for note' unless noteable_id

          author_id, author_found = user_finder.author_id_for(note)

          attributes = {
            noteable_type: note.noteable_type,
            noteable_id: noteable_id,
            project_id: project.id,
            namespace_id: project.project_namespace_id,
            author_id: author_id,
            note: note_body(author_found),
            discussion_id: note.discussion_id,
            system: false,
            created_at: note.created_at,
            updated_at: note.updated_at,
            imported_from: ::Import::HasImportSource::IMPORT_SOURCES[:github]
          }

          Note.new(attributes.merge(importing: true)).validate!

          # We're using bulk_insert here so we can bypass any callbacks.
          # Running these would result in a lot of unnecessary SQL
          # queries being executed when importing large projects.
          # Note: if you're going to replace `legacy_bulk_insert` with something that trigger callback
          # to generate HTML version - you also need to regenerate it in
          # Gitlab::GithubImport::Importer::NoteAttachmentsImporter.
          ids = ApplicationRecord.legacy_bulk_insert(Note.table_name, [attributes], return_ids: true) # rubocop:disable Gitlab/BulkInsert

          push_refs_with_ids(ids, Note, note[:author]&.id, mapper.user_mapper) if mapper.user_mapping_enabled?
        end

        # Returns the ID of the issue or merge request to create the note for.
        def find_noteable_id
          GithubImport::IssuableFinder.new(project, note).database_id
        end

        private

        def note_body(author_found)
          text = MarkdownText.convert_ref_links(note.note, project)
          text = wrap_mentions_in_backticks(text)
          MarkdownText.format(text, note.author, author_found)
        end
      end
    end
  end
end
