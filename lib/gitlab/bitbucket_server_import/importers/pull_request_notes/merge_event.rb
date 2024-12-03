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

            user_id = if user_mapping_enabled?(project)
                        user_finder.uid(
                          username: merge_event[:committer_username],
                          display_name: merge_event[:committer_user]
                        )
                      else
                        user_finder.find_user_id(by: :email, value: merge_event[:committer_email])
                      end

            user_id ||= project.creator_id

            timestamp = merge_event[:merge_timestamp]
            merge_request.update({ merge_commit_sha: merge_event[:merge_commit] })
            metric = create_merge_request_metrics(merged_by_id: user_id, merged_at: timestamp)
            push_reference(project, metric, :merged_by_id, merge_event[:committer_username])

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
