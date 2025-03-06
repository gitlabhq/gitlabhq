# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class CustomStatusType < BaseObject
        graphql_name 'WorkItemWidgetCustomStatus'
        description 'Represents Custom Status widget'

        implements ::Types::WorkItems::WidgetInterface

        field :id, Types::GlobalIDType,
          null: true,
          experiment: { milestone: '17.8' },
          description: 'ID of the custom status.'

        field :name, GraphQL::Types::String,
          null: true,
          experiment: { milestone: '17.8' },
          description: 'Name of the custom status.'

        field :icon_name, GraphQL::Types::String,
          null: true,
          experiment: { milestone: '17.8' },
          description: 'Icon name of the custom status.'

        field :color, GraphQL::Types::String,
          null: true,
          experiment: { milestone: '17.10' },
          description: 'Color of the custom status.'

        field :position, GraphQL::Types::Int,
          null: true,
          experiment: { milestone: '17.10' },
          description: 'Position of the custom status within its category.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
