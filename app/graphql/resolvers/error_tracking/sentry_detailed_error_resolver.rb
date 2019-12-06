# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryDetailedErrorResolver < BaseResolver
      argument :id, GraphQL::ID_TYPE,
                required: true,
                description: 'ID of the Sentry issue'

      def resolve(**args)
        project = object
        current_user = context[:current_user]
        issue_id = GlobalID.parse(args[:id]).model_id

        # Get data from Sentry
        response = ::ErrorTracking::IssueDetailsService.new(
          project,
          current_user,
          { issue_id: issue_id }
        ).execute
        issue = response[:issue]
        issue.gitlab_project = project if issue

        issue
      end
    end
  end
end
