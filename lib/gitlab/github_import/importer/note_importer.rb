# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class NoteImporter
        attr_reader :note, :project, :client, :user_finder

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
          return unless (noteable_id = find_noteable_id)

          author_id, author_found = user_finder.author_id_for(note)

          note_body = MarkdownText.format(note.note, note.author, author_found)

          attributes = {
            noteable_type: note.noteable_type,
            noteable_id: noteable_id,
            project_id: project.id,
            author_id: author_id,
            note: note_body,
            system: false,
            created_at: note.created_at,
            updated_at: note.updated_at
          }

          # We're using bulk_insert here so we can bypass any validations and
          # callbacks. Running these would result in a lot of unnecessary SQL
          # queries being executed when importing large projects.
          Gitlab::Database.main.bulk_insert(Note.table_name, [attributes]) # rubocop:disable Gitlab/BulkInsert
        rescue ActiveRecord::InvalidForeignKey
          # It's possible the project and the issue have been deleted since
          # scheduling this job. In this case we'll just skip creating the note.
        end

        # Returns the ID of the issue or merge request to create the note for.
        def find_noteable_id
          GithubImport::IssuableFinder.new(project, note).database_id
        end
      end
    end
  end
end
