# frozen_string_literal: true

module Mutations
  module AlertManagement
    class Base < BaseMutation
      include Gitlab::Utils::UsageData

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: "Project the alert to mutate is in."

      argument :iid, GraphQL::Types::String,
               required: true,
               description: "IID of the alert to mutate."

      field :alert,
            Types::AlertManagement::AlertType,
            null: true,
            description: "Alert after mutation."

      field :todo,
            Types::TodoType,
            null: true,
            description: "To-do item after mutation."

      field :issue,
            Types::IssueType,
            null: true,
            description: "Issue created after mutation."

      authorize :update_alert_management_alert

      private

      def find_object(project_path:, **args)
        project = Project.find_by_full_path(project_path)

        return unless project

        ::AlertManagement::AlertsFinder.new(current_user, project, args).execute.first
      end
    end
  end
end
