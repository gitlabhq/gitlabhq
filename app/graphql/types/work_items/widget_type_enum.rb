# frozen_string_literal: true

module Types
  module WorkItems
    class WidgetTypeEnum < BaseEnum
      graphql_name 'WorkItemWidgetType'
      description 'Type of a work item widget'

      ::WorkItems::Type.available_widgets.each do |widget|
        value widget.type.to_s.upcase, value: widget.type, description: "#{widget.type.to_s.titleize} widget."
      end
    end
  end
end
