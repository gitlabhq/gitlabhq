# frozen_string_literal: true

module Mutations
  module Issues
    class SetConfidential < Base
      include Mutations::SpamProtection

      graphql_name 'IssueSetConfidential'

      argument :confidential,
               GraphQL::BOOLEAN_TYPE,
               required: true,
               description: 'Whether or not to set the issue as a confidential.'

      def resolve(project_path:, iid:, confidential:)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project
        # Changing confidentiality affects spam checking rules, therefore we need to provide
        # spam_params so a check can be performed.
        spam_params = ::Spam::SpamParams.new_from_request(request: context[:request])

        ::Issues::UpdateService.new(project: project, current_user: current_user, params: { confidential: confidential }, spam_params: spam_params)
          .execute(issue)
        check_spam_action_response!(issue)

        {
          issue: issue,
          errors: errors_on_object(issue)
        }
      end
    end
  end
end
