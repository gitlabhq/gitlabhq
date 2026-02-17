# frozen_string_literal: true

module Types
  module WorkItems
    class WidgetTypeEnum < BaseEnum
      graphql_name 'WorkItemWidgetType'
      description 'Type of a work item widget'

      def self.widget_definition_class
        if Feature.enabled?(:work_item_system_defined_type, :instance)
          ::WorkItems::TypesFramework::SystemDefined::WidgetDefinition
        else
          ::WorkItems::WidgetDefinition
        end
      end

      widget_definition_class.widget_classes.each do |cls|
        value cls.type.to_s.upcase, value: cls.type, description: "#{cls.type.to_s.titleize} widget."
      end
    end
  end
end
