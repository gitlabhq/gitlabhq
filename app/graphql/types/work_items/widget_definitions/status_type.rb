# frozen_string_literal: true

module Types
  module WorkItems
    module WidgetDefinitions
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization too granular, parent type is authorized
      class StatusType < BaseObject
        graphql_name 'WorkItemWidgetDefinitionStatus'
        description 'Represents a Status widget definition'

        implements ::Types::WorkItems::WidgetDefinitionInterface

        field :allowed_statuses, ::Types::WorkItems::Widgets::StatusType.connection_type,
          null: true, experiment: { milestone: '17.8' },
          description: 'Allowed statuses for the work item type.',
          resolver: Resolvers::WorkItems::Widgets::StatusResolver
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
