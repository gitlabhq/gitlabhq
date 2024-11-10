# frozen_string_literal: true

module Mutations
  module Issues
    class SetConfidential < Base
      graphql_name 'IssueSetConfidential'

      include Mutations::SpamProtection

      argument :confidential,
        GraphQL::Types::Boolean,
        required: true,
        description: 'Whether or not to set the issue as a confidential.'

      def resolve(project_path:, iid:, confidential:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project
        # Changing confidentiality affects spam checking rules, therefore we need to perform a spam check
        ::Issues::UpdateService.new(
          container: project,
          current_user: current_user,
          params: { confidential: confidential },
          perform_spam_check: true
        ).execute(issue)
        check_spam_action_response!(issue)

        {
          issue: issue.reset,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end
