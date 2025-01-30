# frozen_string_literal: true

module WorkItems
  class CreateService < Issues::CreateService
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
    rescue ::Issuable::Callbacks::Base::Error => e
      error(e.message, :unprocessable_entity)
    end

    def parent
      container
    end

    private

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
