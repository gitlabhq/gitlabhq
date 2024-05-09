# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      module PullRequestNotes
        class ApprovedEvent < BaseImporter
          include ::Gitlab::Import::MergeRequestHelpers

          def execute(approved_event)
            log_info(
              import_stage: 'import_approved_event',
              message: 'starting',
              iid: merge_request.iid,
              event_id: approved_event[:id]
            )

            user_id = user_finder.find_user_id(by: :username, value: approved_event[:approver_username]) ||
              user_finder.find_user_id(by: :email, value: approved_event[:approver_email])

            if user_id.nil?
              log_info(
                import_stage: 'import_approved_event',
                message: 'skipped due to missing user',
                iid: merge_request.iid,
                event_id: approved_event[:id]
              )

              return
            end

            submitted_at = approved_event[:created_at] || merge_request[:updated_at]

            create_approval!(project.id, merge_request.id, user_id, submitted_at)
            create_reviewer!(merge_request.id, user_id, submitted_at)

            log_info(
              import_stage: 'import_approved_event',
              message: 'finished',
              iid: merge_request.iid,
              event_id: approved_event[:id]
            )
          end
        end
      end
    end
  end
end
