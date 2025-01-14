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

            user_id = if user_mapping_enabled?(project)
                        user_finder.uid(
                          username: approved_event[:approver_username],
                          display_name: approved_event[:approver_name]
                        )
                      else
                        user_finder.find_user_id(by: :email, value: approved_event[:approver_email])
                      end

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

            approval, approval_note = create_approval!(project.id, merge_request.id, user_id, submitted_at)
            push_reference(project, approval, :user_id, approved_event[:approver_username]) if approval
            push_reference(project, approval_note, :author_id, approved_event[:approver_username]) if approval_note

            reviewer = create_reviewer!(merge_request.id, user_id, submitted_at)
            push_reference(project, reviewer, :user_id, approved_event[:approver_username]) if reviewer

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
