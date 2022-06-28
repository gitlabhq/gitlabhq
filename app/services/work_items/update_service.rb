# frozen_string_literal: true

module WorkItems
  class UpdateService < ::Issues::UpdateService
    def initialize(project:, current_user: nil, params: {}, spam_params: nil, widget_params: {})
      super(project: project, current_user: current_user, params: params, spam_params: nil)

      @widget_params = widget_params
      @widget_services = {}
    end

    private

    def update(work_item)
      execute_widgets(work_item: work_item, callback: :update)

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
      service_class = begin
        "WorkItems::Widgets::#{widget.type.capitalize}Service::UpdateService".constantize
      rescue NameError
        nil
      end

      return unless service_class

      @widget_services[widget] ||= service_class.new(widget: widget, current_user: current_user)
    end
  end
end
