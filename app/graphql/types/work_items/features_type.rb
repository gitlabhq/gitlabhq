# frozen_string_literal: true

module Types
  module WorkItems
    # rubocop:disable Graphql/AuthorizeTypes -- only a wrapper type
    class FeaturesType < BaseObject
      graphql_name 'WorkItemFeatures'

      def self.widget_definition_class
        if Feature.enabled?(:work_item_system_defined_type, :instance)
          ::WorkItems::TypesFramework::SystemDefined::WidgetDefinition
        else
          ::WorkItems::WidgetDefinition
        end
      end

      widget_definition_class.widget_classes.each do |widget_class|
        widget_type = widget_class.type

        field widget_type,
          ::Types::WorkItems::WidgetInterface.type_mappings[widget_class],
          null: true,
          description: "#{widget_type.to_s.humanize} widget of the work item. " \
            "Returns `null` if the widget is not available for the work item."

        define_method widget_type do
          object.get_widget(widget_type)
        end
      end
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
