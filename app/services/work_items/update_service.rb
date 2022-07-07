# frozen_string_literal: true

module WorkItems
  class UpdateService < ::Issues::UpdateService
    def initialize(project:, current_user: nil, params: {}, spam_params: nil, widget_params: {})
      params[:widget_params] = true if widget_params.present?

      super(project: project, current_user: current_user, params: params, spam_params: nil)

      @widget_params = widget_params
      @widget_services = {}
    end

    def execute(work_item)
      updated_work_item = super

      if updated_work_item.valid?
        success(payload(work_item))
      else
        error(updated_work_item.errors.full_messages, :unprocessable_entity, pass_back: payload(updated_work_item))
      end
    rescue ::WorkItems::Widgets::BaseService::WidgetError => e
      error(e.message, :unprocessable_entity)
    end

    private

    def update(work_item)
      execute_widgets(work_item: work_item, callback: :update)

      super
    end

    def transaction_update(work_item, opts = {})
      execute_widgets(work_item: work_item, callback: :before_update_in_transaction)

      super
    end

    def after_update(work_item)
      super

      GraphqlTriggers.issuable_title_updated(work_item) if work_item.previous_changes.key?(:title)
    end

    def execute_widgets(work_item:, callback:)
      work_item.widgets.each do |widget|
        widget_service(widget).try(callback, params: @widget_params[widget.class.api_symbol])
      end
    end

    def widget_service(widget)
      @widget_services[widget] ||= widget_service_class(widget)&.new(widget: widget, current_user: current_user)
    end

    def widget_service_class(widget)
      "WorkItems::Widgets::#{widget.type.capitalize}Service::UpdateService".constantize
    rescue NameError
      nil
    end

    def payload(work_item)
      { work_item: work_item }
    end
  end
end
