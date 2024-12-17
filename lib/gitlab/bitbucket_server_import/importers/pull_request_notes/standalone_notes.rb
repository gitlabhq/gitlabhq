# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      module PullRequestNotes
        class StandaloneNotes < BaseNoteDiffImporter
          def execute(comment)
            log_info(
              import_stage: 'import_standalone_notes_comments',
              message: 'starting',
              iid: merge_request.iid,
              comment_id: comment[:id]
            )

            note = merge_request.notes.create!(pull_request_comment_attributes(comment))
            push_reference(note.project, note, :author_id, comment[:author_username])

            comment[:comments].each do |reply|
              note = merge_request.notes.create!(pull_request_comment_attributes(reply))
              push_reference(note.project, note, :author_id, reply[:author_username])
            end
          rescue StandardError => e
            Gitlab::ErrorTracking.log_exception(
              e,
              import_stage: 'import_standalone_notes_comments',
              merge_request_id: merge_request.id,
              comment_id: comment[:id],
              error: e.message
            )
          ensure
            log_info(
              import_stage: 'import_standalone_notes_comments',
              message: 'finished',
              iid: merge_request.iid,
              comment_id: comment[:id]
            )
          end

          def pull_request_comment_attributes(comment)
            super(comment).merge(imported_from: ::Import::SOURCE_BITBUCKET_SERVER)
          end
        end
      end
    end
  end
end
