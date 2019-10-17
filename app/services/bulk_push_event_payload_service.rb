# frozen_string_literal: true

class BulkPushEventPayloadService
  def initialize(event, push_data)
    @event = event
    @push_data = push_data
  end

  def execute
    @event.build_push_event_payload(
      action: @push_data[:action],
      commit_count: 0,
      ref_count: @push_data[:ref_count],
      ref_type: @push_data[:ref_type]
    )

    @event.push_event_payload.tap(&:save!)
  end
end
