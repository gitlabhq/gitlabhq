# frozen_string_literal: true

module WorkItems
  module WidgetableService
    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def initialize_callbacks!(work_item)
      interpret_quick_actions!(work_item, @widget_params, params)

      @callbacks = work_item.widgets.filter_map do |widget|
        callback_class = widget.class.try(:callback_class)
        callback_params = @widget_params[widget.class.api_symbol]

        if new_type_excludes_widget?(widget, work_item.resource_parent)
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

    def new_type_excludes_widget?(widget, resource_parent)
      return false unless params[:work_item_type]

      params[:work_item_type].widget_classes(resource_parent).exclude?(widget.class)
    end

    def interpret_quick_actions!(work_item, widget_params, attributes = {})
      return unless work_item.has_widget?(:description)

      widget_description_param = widget_params[::WorkItems::Widgets::Description.api_symbol]
      return unless widget_description_param

      merge_quick_actions_into_params!(work_item, params: widget_description_param)

      # cleanup `description` param so that it is not passed into common params after transform_quick_action_params
      quick_action_params = widget_description_param.dup
      quick_action_params.delete(:description)

      parsed_params = work_item.transform_quick_action_params(quick_action_params)

      widget_params.merge!(parsed_params[:widgets])
      attributes.merge!(parsed_params[:common])
    end
  end
end
