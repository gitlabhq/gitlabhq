# frozen_string_literal: true

module WorkItems
  module WidgetableService
    extend ActiveSupport::Concern

    included do
      attr_reader :widget_params
    end

    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def initialize_callbacks!(work_item)
      @callbacks = work_item.widgets.filter_map do |widget|
        callback_class = widget.class.try(:callback_class)
        callback_params = widget_params[widget.class.api_symbol]

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

    def handle_quick_actions(work_item)
      # Do not handle quick actions from params[:description] unless the work item is the default Issue.
      super if work_item.work_item_type == WorkItems::Type.default_by_type(:issue)

      # Handle quick actions from description widget depending on the available widgets for the type
      handle_widget_quick_actions!(work_item)
    end

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

    def handle_widget_quick_actions!(work_item)
      return unless work_item.has_widget?(:description)

      description_widget_params = widget_params[::WorkItems::Widgets::Description.api_symbol]
      return unless description_widget_params

      merge_quick_actions_into_params!(work_item, params: description_widget_params)

      # When there are residual quick actions, `#handle_quick_actions` will set a description param
      # with the sanitized description. We need to remove it here so it does not override the description
      # value we are trying to set from the description widget. This description is also sanitized already
      # since it uses the same `#merge_quick_actions_into_params!` method.
      params.delete(:description) if description_widget_params[:description].present?

      # exclude `description` param so that it is not passed into common params after transform_quick_action_params
      parsed_params = work_item.transform_quick_action_params(description_widget_params.except(:description))

      widget_params.merge!(parsed_params[:widgets])
      params.merge!(parsed_params[:common])
    end
  end
end
