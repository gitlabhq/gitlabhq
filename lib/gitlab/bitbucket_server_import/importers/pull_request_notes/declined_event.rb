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

            user_id = if user_mapping_enabled?(project)
                        user_finder.uid(
                          username: declined_event[:decliner_username],
                          display_name: declined_event[:decliner_name]
                        )
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

            event = record_event(user_id)
            push_reference(project, event, :author_id, declined_event[:decliner_username])

            metric = create_merge_request_metrics(
              latest_closed_by_id: user_id,
              latest_closed_at: declined_event[:created_at]
            )
            push_reference(project, metric, :latest_closed_by_id, declined_event[:decliner_username])

            log_info(
              import_stage: 'import_declined_event',
              message: 'finished',
              iid: merge_request.iid,
              event_id: declined_event[:id]
            )
          end

          private

          def record_event(user_id)
            Event.create!(
              project_id: project.id,
              author_id: user_id,
              action: 'closed',
              target_type: 'MergeRequest',
              target_id: merge_request.id,
              imported_from: ::Import::HasImportSource::IMPORT_SOURCES[:bitbucket_server]
            )
          end
        end
      end
    end
  end
end
