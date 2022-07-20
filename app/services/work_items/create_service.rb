# frozen_string_literal: true

module WorkItems
  class CreateService < Issues::CreateService
    include ::Services::ReturnServiceResponses
    include WidgetableService

    def initialize(project:, current_user: nil, params: {}, spam_params:, widget_params: {})
      super(
        project: project,
        current_user: current_user,
        params: params,
        spam_params: spam_params,
        build_service: ::WorkItems::BuildService.new(project: project, current_user: current_user, params: params)
      )
      @widget_params = widget_params
    end

    def execute
      unless @current_user.can?(:create_work_item, @project)
        return error(_('Operation not allowed'), :forbidden)
      end

      work_item = super

      if work_item.valid?
        success(payload(work_item))
      else
        error(work_item.errors.full_messages, :unprocessable_entity, pass_back: payload(work_item))
      end
    rescue ::WorkItems::Widgets::BaseService::WidgetError => e
      error(e.message, :unprocessable_entity)
    end

    def transaction_create(work_item)
      super.tap do |save_result|
        if save_result
          execute_widgets(work_item: work_item, callback: :after_create_in_transaction,
                          widget_params: @widget_params)
        end
      end
    end

    private

    def payload(work_item)
      { work_item: work_item }
    end
  end
end
