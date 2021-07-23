# frozen_string_literal: true

module Mutations
  module AlertManagement
    module Alerts
      class SetAssignees < Base
        graphql_name 'AlertSetAssignees'

        argument :assignee_usernames,
                 [GraphQL::Types::String],
                 required: true,
                 description: 'The usernames to assign to the alert. Replaces existing assignees by default.'

        argument :operation_mode,
                 Types::MutationOperationModeEnum,
                 required: false,
                 description: 'The operation to perform. Defaults to REPLACE.'

        def resolve(args)
          alert = authorized_find!(project_path: args[:project_path], iid: args[:iid])
          result = set_assignees(alert, args[:assignee_usernames], args[:operation_mode])

          track_usage_event(:incident_management_alert_assigned, current_user.id)

          prepare_response(result)
        end

        private

        def set_assignees(alert, assignee_usernames, operation_mode)
          operation_mode ||= Types::MutationOperationModeEnum.enum[:replace]

          original_assignees = alert.assignees
          target_users = find_target_users(assignee_usernames)

          assignees = case Types::MutationOperationModeEnum.enum.key(operation_mode).to_sym
                      when :replace then target_users.uniq
                      when :append then (original_assignees + target_users).uniq
                      when :remove then (original_assignees - target_users)
                      end

          ::AlertManagement::Alerts::UpdateService.new(alert, current_user, assignees: assignees).execute
        end

        def find_target_users(assignee_usernames)
          UsersFinder.new(current_user, username: assignee_usernames).execute
        end

        def prepare_response(result)
          {
            alert: result.payload[:alert],
            errors: result.error? ? [result.message] : []
          }
        end
      end
    end
  end
end
