# frozen_string_literal: true

module Mutations
  module Issues
    class Update < Base
      graphql_name 'UpdateIssue'

      argument :title,
                GraphQL::STRING_TYPE,
                required: false,
                description: copy_field_description(Types::IssueType, :title)

      argument :description,
                GraphQL::STRING_TYPE,
                required: false,
                description: copy_field_description(Types::IssueType, :description)

      argument :due_date,
               Types::TimeType,
               required: false,
               description: copy_field_description(Types::IssueType, :due_date)

      argument :confidential,
               GraphQL::BOOLEAN_TYPE,
               required: false,
               description: copy_field_description(Types::IssueType, :confidential)

      def resolve(project_path:, iid:, **args)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        ::Issues::UpdateService.new(project, current_user, args).execute(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end

Mutations::Issues::Update.prepend_if_ee('::EE::Mutations::Issues::Update')
