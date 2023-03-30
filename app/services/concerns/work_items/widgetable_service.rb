# frozen_string_literal: true

module WorkItems
  module WidgetableService
    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def initialize_callbacks!(work_item)
      @callbacks = work_item.widgets.filter_map do |widget|
        callback_class = widget.class.try(:callback_class)
        callback_params = @widget_params[widget.class.api_symbol]

        if new_type_excludes_widget?(widget)
          callback_params = {} if callback_params.nil?
          callback_params[:excluded_in_new_type] = true
        end

        next if callback_class.nil? || callback_params.blank?

        callback_class.new(issuable: work_item, current_user: current_user, params: callback_params)
      end

      @callbacks.each(&:after_initialize)
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def execute_widgets(work_item:, callback:, widget_params: {}, service_params: {})
      work_item.widgets.each do |widget|
        widget_service(widget, service_params).try(callback, params: widget_params[widget.class.api_symbol] || {})
      end
    end

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def widget_service(widget, service_params)
      @widget_services ||= {}
      return @widget_services[widget] if @widget_services.has_key?(widget)

      @widget_services[widget] = widget_service_class(widget)&.new(
        widget: widget,
        current_user: current_user,
        service_params: service_params
      )
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def widget_service_class(widget)
      "WorkItems::Widgets::#{widget.type.to_s.camelize}Service::#{self.class.name.demodulize}".constantize
    rescue NameError
      nil
    end

    private

    def new_type_excludes_widget?(widget)
      return false unless params[:work_item_type]

      params[:work_item_type].widgets.exclude?(widget.class)
    end
  end
end
