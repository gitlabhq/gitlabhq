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
        next if callback_class.nil?

        callback_params = widget_params[widget.class.api_symbol] || {}
        callback_params[:excluded_in_new_type] = true if new_type_excludes_widget?(widget, work_item.resource_parent)

        if callback_class.const_defined?(:ALLOWED_PARAMS)
          callback_params.reverse_merge!(params.slice(*callback_class::ALLOWED_PARAMS))
        end

        next if callback_params.blank? && !execute_without_params(callback_class)

        callback_class.new(issuable: work_item, current_user: current_user, params: callback_params)
      end

      remove_callback_params
      @callbacks.each(&:after_initialize)
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables

    def handle_quick_actions(work_item)
      # Unify description parameters into widget params for quick action processing
      if params[:description].present?
        description_widget_params = widget_params[::WorkItems::Widgets::Description.api_symbol] ||= {}
        description_widget_params.reverse_merge!(params.slice(:description))
      end

      # Handle quick actions from description widget depending on the available widgets for the type
      handle_widget_quick_actions!(work_item)
    end

    def params_include_state_and_status_changes?
      params.include?(:state_event) && widget_params.dig(:status_widget, :status)
    end

    private

    def new_type_excludes_widget?(widget, resource_parent)
      return false unless params[:work_item_type]

      params[:work_item_type].widget_classes(resource_parent).exclude?(widget.class)
    end

    def handle_widget_quick_actions!(work_item)
      return unless work_item.has_widget?(:description)

      # We need to run merge_quick_actions_into_params! even if there is no given description param because
      # we want to parse and remove any residual quick actions
      description_widget_params = widget_params[::WorkItems::Widgets::Description.api_symbol] ||= {}

      merge_quick_actions_into_params!(work_item, params: description_widget_params)

      # exclude `description` param so that it is not passed into common params after transform_quick_action_params
      parsed_params = work_item.transform_quick_action_params(description_widget_params.except(:description))

      widget_params.deep_merge!(parsed_params[:widgets])
      params.merge!(parsed_params[:common])
    end
  end
end
