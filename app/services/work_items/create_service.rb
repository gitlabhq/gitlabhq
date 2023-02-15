# frozen_string_literal: true

module WorkItems
  class CreateService < Issues::CreateService
    include WidgetableService

    def initialize(project:, spam_params:, current_user: nil, params: {}, widget_params: {})
      super(
        project: project,
        current_user: current_user,
        params: params,
        spam_params: spam_params,
        build_service: ::WorkItems::BuildService.new(container: project, current_user: current_user, params: params)
      )
      @widget_params = widget_params
    end

    def execute
      result = super
      return result if result.error?

      work_item = result[:issue]

      if work_item.valid?
        success(payload(work_item))
      else
        error(work_item.errors.full_messages, :unprocessable_entity, pass_back: payload(work_item))
      end
    rescue ::WorkItems::Widgets::BaseService::WidgetError => e
      error(e.message, :unprocessable_entity)
    end

    def before_create(work_item)
      execute_widgets(work_item: work_item, callback: :before_create_callback,
                      widget_params: @widget_params)

      super
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

    def authorization_action
      :create_work_item
    end

    def payload(work_item)
      { work_item: work_item }
    end
  end
end
