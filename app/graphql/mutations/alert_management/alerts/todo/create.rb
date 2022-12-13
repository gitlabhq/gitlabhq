# frozen_string_literal: true

module Mutations
  module AlertManagement
    module Alerts
      module Todo
        class Create < Base
          graphql_name 'AlertTodoCreate'

          def resolve(args)
            alert = authorized_find!(project_path: args[:project_path], iid: args[:iid])
            result = ::AlertManagement::Alerts::Todo::CreateService.new(alert, current_user).execute

            track_alert_events('incident_management_alert_todo', alert)

            prepare_response(result)
          end

          private

          def prepare_response(result)
            {
              alert: result.payload[:alert],
              todo: result.payload[:todo],
              errors: result.error? ? [result.message] : []
            }
          end
        end
      end
    end
  end
end
