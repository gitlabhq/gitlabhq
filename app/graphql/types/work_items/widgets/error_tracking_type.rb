# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class ErrorTrackingType < BaseObject
        graphql_name 'WorkItemWidgetErrorTracking'
        description 'Represents the error tracking widget'

        implements ::Types::WorkItems::WidgetInterface

        field :identifier, GraphQL::Types::BigInt, null: true,
          description: 'Error tracking issue id.', method: :sentry_issue_identifier
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
