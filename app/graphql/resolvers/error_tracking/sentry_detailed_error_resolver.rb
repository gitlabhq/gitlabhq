# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryDetailedErrorResolver < BaseResolver
      type Types::ErrorTracking::SentryDetailedErrorType, null: true

      argument :id, ::Types::GlobalIDType[::Gitlab::ErrorTracking::DetailedError],
        required: true,
        description: 'ID of the Sentry issue.'

      def resolve(id:)
        # Get data from Sentry
        response = ::ErrorTracking::IssueDetailsService.new(
          project,
          current_user,
          { issue_id: id.model_id, tracking_event: :error_tracking_view_details }
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
