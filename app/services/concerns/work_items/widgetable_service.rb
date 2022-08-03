# frozen_string_literal: true

module WorkItems
  module WidgetableService
    def execute_widgets(work_item:, callback:, widget_params: {})
      work_item.widgets.each do |widget|
        widget_service(widget).try(callback, params: widget_params[widget.class.api_symbol])
      end
    end

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def widget_service(widget)
      @widget_services ||= {}
      return @widget_services[widget] if @widget_services.has_key?(widget)

      @widget_services[widget] = widget_service_class(widget)&.new(widget: widget, current_user: current_user)
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def widget_service_class(widget)
      "WorkItems::Widgets::#{widget.type.to_s.camelize}Service::#{self.class.name.demodulize}".constantize
    rescue NameError
      nil
    end
  end
end
