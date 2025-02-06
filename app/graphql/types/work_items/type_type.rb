# frozen_string_literal: true

module Types
  module WorkItems
    class TypeType < BaseObject
      graphql_name 'WorkItemType'

      authorize :read_work_item_type

      field :icon_name, GraphQL::Types::String,
        null: true,
        description: 'Icon name of the work item type.'
      field :id, ::Types::GlobalIDType[::WorkItems::Type],
        null: false,
        description: 'Global ID of the work item type.'
      field :name, GraphQL::Types::String,
        null: false,
        description: 'Name of the work item type.'
      field :widget_definitions, [::Types::WorkItems::WidgetDefinitionInterface],
        null: true,
        description: 'Available widgets for the work item type.',
        method: :widgets,
        experiment: { milestone: '16.7' }

      field :supported_conversion_types, [::Types::WorkItems::TypeType],
        null: true,
        description: 'Supported conversion types for the work item type.',
        experiment: { milestone: '17.8' }

      def widget_definitions
        object.widgets(context[:resource_parent])
      end

      def supported_conversion_types
        object.supported_conversion_types(context[:resource_parent], current_user)
      end
    end
  end
end
