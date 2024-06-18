# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      module PullRequestNotes
        class DeclinedEvent < BaseImporter
          include ::Gitlab::Import::MergeRequestHelpers

          def execute(declined_event)
            log_info(
              import_stage: 'import_declined_event',
              message: 'starting',
              iid: merge_request.iid,
              event_id: declined_event[:id]
            )

            user_id = if Feature.enabled?(:bitbucket_server_user_mapping_by_username, project, type: :ops)
                        user_finder.find_user_id(by: :username, value: declined_event[:decliner_username])
                      else
                        user_finder.find_user_id(by: :email, value: declined_event[:decliner_email])
                      end

            if user_id.nil?
              log_info(
                import_stage: 'import_declined_event',
                message: 'skipped due to missing user',
                iid: merge_request.iid,
                event_id: declined_event[:id]
              )

              return
            end

            # `user_finder` did some optimization to cache the `user_id`, let's keep avoid loading the `User` object
            # however, we need to wrap the `user_id` with `User` model so that the downstream logic can work properly
            user = User.new(id: user_id)

            SystemNoteService.change_status(merge_request, merge_request.target_project, user, 'closed', nil)
            EventCreateService.new.close_mr(merge_request, user)
            create_merge_request_metrics(latest_closed_by_id: user_id, latest_closed_at: declined_event[:created_at])

            log_info(
              import_stage: 'import_declined_event',
              message: 'finished',
              iid: merge_request.iid,
              event_id: declined_event[:id]
            )
          end
        end
      end
    end
  end
end
