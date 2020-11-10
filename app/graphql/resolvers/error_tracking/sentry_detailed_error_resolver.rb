# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryDetailedErrorResolver < BaseResolver
      type Types::ErrorTracking::SentryDetailedErrorType, null: true

      argument :id, GraphQL::ID_TYPE,
                required: true,
                description: 'ID of the Sentry issue'

      def resolve(**args)
        current_user = context[:current_user]
        issue_id = GlobalID.parse(args[:id])&.model_id

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

      private

      def project
        return object.gitlab_project if object.respond_to?(:gitlab_project)

        object
      end
    end
  end
end
