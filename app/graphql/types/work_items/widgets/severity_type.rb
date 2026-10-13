# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class SeverityType < BaseObject
        graphql_name 'WorkItemWidgetSeverity'
        description 'Represents the severity widget'

        authorize_granular_token skip_reason: :parent_authorizes

        implements ::Types::WorkItems::WidgetInterface

        field :severity, ::Types::IssuableSeverityEnum,
          null: true,
          description: 'Severity of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
