# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class WeightType < BaseObject
        graphql_name 'WorkItemWidgetWeight'
        description 'Represents a weight widget'

        implements Types::WorkItems::WidgetInterface

        field :weight, GraphQL::Types::Int, null: true,
              description: 'Weight of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
