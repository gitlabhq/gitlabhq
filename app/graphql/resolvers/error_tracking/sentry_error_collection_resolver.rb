# frozen_string_literal: true

module Resolvers
  module ErrorTracking
    class SentryErrorCollectionResolver < BaseResolver
      type Types::ErrorTracking::SentryErrorCollectionType, null: true

      def resolve(**args)
        project = object

        service = ::ErrorTracking::ListIssuesService.new(
          project,
          context[:current_user]
        )

        Gitlab::ErrorTracking::ErrorCollection.new(
          external_url: service.external_url,
          project: project
        )
      end
    end
  end
end
