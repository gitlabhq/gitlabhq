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

      field :unavailable_widgets_on_conversion, [::Types::WorkItems::WidgetDefinitionInterface],
        null: true,
        description: 'Widgets that will be lost when converting from source work item type to target work item type.' do
          argument :target, ::Types::GlobalIDType[::WorkItems::Type],
            required: true,
            description: 'Target work item type to convert to.'
        end

      def widget_definitions
        object.widgets(context[:resource_parent])
      end

      def supported_conversion_types
        object.supported_conversion_types(context[:resource_parent], current_user)
      end

      def unavailable_widgets_on_conversion(target:)
        source_type = object
        target_type = GitlabSchema.find_by_gid(target).sync

        return [] unless source_type && target_type

        source_type.unavailable_widgets_on_conversion(target_type, context[:resource_parent])
      end
    end
  end
end
