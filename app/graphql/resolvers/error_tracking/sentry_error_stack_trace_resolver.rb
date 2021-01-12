# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryErrorStackTraceResolver < BaseResolver
      type Types::ErrorTracking::SentryErrorStackTraceType, null: true

      argument :id, ::Types::GlobalIDType[::Gitlab::ErrorTracking::DetailedError],
                required: true,
                description: 'ID of the Sentry issue.'

      def resolve(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Gitlab::ErrorTracking::DetailedError].coerce_isolated_input(id)

        # Get data from Sentry
        response = ::ErrorTracking::IssueLatestEventService.new(
          project,
          current_user,
          { issue_id: id.model_id }
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
