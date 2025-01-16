# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitions
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization too granular, parent type is authorized
      class CustomStatusType < BaseObject
        graphql_name 'WorkItemWidgetDefinitionCustomStatus'
        description 'Represents an Custom Status widget definition'

        implements ::Types::WorkItems::WidgetDefinitionInterface

        field :allowed_custom_statuses, ::Types::WorkItems::Widgets::CustomStatusType.connection_type,
          null: true, experiment: { milestone: '17.8' },
          description: 'Allowed custom statuses for the work item type.',
          resolver: Resolvers::WorkItems::Widgets::CustomStatusResolver
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
