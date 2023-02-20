# frozen_string_literal: true

module Types
  module WorkItems
    class WidgetTypeEnum < BaseEnum
      graphql_name 'WorkItemWidgetType'
      description 'Type of a work item widget'

      ::WorkItems::WidgetDefinition.widget_classes.each do |cls|
        value cls.type.to_s.upcase, value: cls.type, description: "#{cls.type.to_s.titleize} widget."
      end
    end
  end
end
