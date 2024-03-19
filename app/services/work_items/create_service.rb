# frozen_string_literal: true

module WorkItems
  class CreateService < Issues::CreateService
    extend ::Gitlab::Utils::Override
    include WidgetableService

    def initialize(container:, perform_spam_check: true, current_user: nil, params: {}, widget_params: {})
      super(
        container: container,
        current_user: current_user,
        params: params,
        perform_spam_check: perform_spam_check,
        build_service: ::WorkItems::BuildService.new(container: container, current_user: current_user, params: params)
      )
      @widget_params = widget_params
    end

    def execute(skip_system_notes: false)
      result = skip_system_notes? ? super(skip_system_notes: true) : super
      return result if result.error?

      work_item = result[:issue]

      if work_item.valid?
        publish_event(work_item)
        success(payload(work_item))
      else
        error(work_item.errors.full_messages, :unprocessable_entity, pass_back: payload(work_item))
      end
    rescue ::WorkItems::Widgets::BaseService::WidgetError => e
      error(e.message, :unprocessable_entity)
    end

    def before_create(work_item)
      execute_widgets(
        work_item: work_item,
        callback: :before_create_callback,
        widget_params: @widget_params
      )

      super
    end

    def transaction_create(work_item)
      super.tap do |save_result|
        if save_result
          execute_widgets(
            work_item: work_item,
            callback: :after_create_in_transaction,
            widget_params: @widget_params
          )
        end
      end
    end

    def prepare_create_params(work_item)
      execute_widgets(
        work_item: work_item,
        callback: :prepare_create_params,
        widget_params: @widget_params,
        service_params: params
      )

      super
    end

    def parent
      container
    end

    private

    override :handle_quick_actions
    def handle_quick_actions(work_item)
      # Do not handle quick actions unless the work item is the default Issue.
      # The available quick actions for a work item depend on its type and widgets.
      return if work_item.work_item_type != WorkItems::Type.default_by_type(:issue)

      super
    end

    def authorization_action
      :create_work_item
    end

    def payload(work_item)
      { work_item: work_item }
    end

    def skip_system_notes?
      false
    end

    def publish_event(work_item)
      work_item.run_after_commit_or_now do
        Gitlab::EventStore.publish(
          WorkItems::WorkItemCreatedEvent.new(data: {
            id: work_item.id,
            namespace_id: work_item.namespace_id
          })
        )
      end
    end
  end
end

WorkItems::CreateService.prepend_mod
