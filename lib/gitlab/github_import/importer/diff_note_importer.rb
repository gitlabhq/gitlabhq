# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class DiffNoteImporter
        attr_reader :note, :project, :client, :user_finder

        # note - An instance of `Gitlab::GithubImport::Representation::DiffNote`.
        # project - An instance of `Project`.
        # client - An instance of `Gitlab::GithubImport::Client`.
        def initialize(note, project, client)
          @note = note
          @project = project
          @client = client
          @user_finder = UserFinder.new(project, client)
        end

        def execute
          return unless (mr_id = find_merge_request_id)

          author_id, author_found = user_finder.author_id_for(note)

          note_body =
            MarkdownText.format(note.note, note.author, author_found)

          attributes = {
            noteable_type: 'MergeRequest',
            noteable_id: mr_id,
            project_id: project.id,
            author_id: author_id,
            note: note_body,
            system: false,
            commit_id: note.commit_id,
            line_code: note.line_code,
            type: 'LegacyDiffNote',
            created_at: note.created_at,
            updated_at: note.updated_at,
            st_diff: note.diff_hash.to_yaml
          }

          # It's possible that during an import we'll insert tens of thousands
          # of diff notes. If we were to use the Note/LegacyDiffNote model here
          # we'd also have to run additional queries for both validations and
          # callbacks, putting a lot of pressure on the database.
          #
          # To work around this we're using bulk_insert with a single row. This
          # allows us to efficiently insert data (even if it's just 1 row)
          # without having to use all sorts of hacks to disable callbacks.
          Gitlab::Database.bulk_insert(LegacyDiffNote.table_name, [attributes])
        rescue ActiveRecord::InvalidForeignKey
          # It's possible the project and the issue have been deleted since
          # scheduling this job. In this case we'll just skip creating the note.
        end

        # Returns the ID of the merge request this note belongs to.
        def find_merge_request_id
          GithubImport::IssuableFinder.new(project, note).database_id
        end
      end
    end
  end
end
