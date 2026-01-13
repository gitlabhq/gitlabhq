# frozen_string_literal: true

module WorkItems
  class CreateService < Issues::CreateService
    include WidgetableService

    def initialize(container:, perform_spam_check: true, current_user: nil, params: {}, widget_params: {})
      @create_source = params.delete(:create_source)
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

      # we need to pass `work_item` in error response to properly display errors
      return error(result.message, result.http_status, pass_back: payload(result[:issue])) if result.error?

      work_item = result[:issue]

      if work_item.valid?
        track_work_item_create(work_item)
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

    def track_work_item_create(work_item)
      candidate = "work_item_create_#{@create_source}" if @create_source.present?
      event_name = candidate if Gitlab::WorkItems::Instrumentation::EventActions.valid_event?(candidate)
      event_name ||= Gitlab::WorkItems::Instrumentation::EventActions::CREATE

      ::Gitlab::WorkItems::Instrumentation::TrackingService.new(
        work_item: work_item,
        current_user: current_user,
        event: event_name
      ).execute
    end
  end
end

WorkItems::CreateService.prepend_mod
