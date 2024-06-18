# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      module PullRequestNotes
        class MergeEvent < BaseImporter
          include ::Gitlab::Import::MergeRequestHelpers

          def execute(merge_event)
            log_info(
              import_stage: 'import_merge_event',
              message: 'starting',
              iid: merge_request.iid,
              event_id: merge_event[:id]
            )

            committer = merge_event[:committer_email]

            user_id = user_finder.find_user_id(by: :email, value: committer) || project.creator_id
            timestamp = merge_event[:merge_timestamp]
            merge_request.update({ merge_commit_sha: merge_event[:merge_commit] })
            create_merge_request_metrics(merged_by_id: user_id, merged_at: timestamp)

            log_info(
              import_stage: 'import_merge_event',
              message: 'finished',
              iid: merge_request.iid,
              event_id: merge_event[:id]
            )
          end
        end
      end
    end
  end
end
