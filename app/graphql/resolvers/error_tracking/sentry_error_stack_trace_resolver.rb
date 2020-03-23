# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryErrorStackTraceResolver < BaseResolver
      argument :id, GraphQL::ID_TYPE,
                required: true,
                description: 'ID of the Sentry issue'

      def resolve(**args)
        issue_id = GlobalID.parse(args[:id])&.model_id

        # Get data from Sentry
        response = ::ErrorTracking::IssueLatestEventService.new(
          project,
          current_user,
          { issue_id: issue_id }
        ).execute

        event = response[:latest_event]
        event.gitlab_project = project if event

        event
      end

      private

      def project
        return object.gitlab_project if object.respond_to?(:gitlab_project)

        object
      end
    end
  end
end
