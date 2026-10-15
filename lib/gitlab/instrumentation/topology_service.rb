# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class TopologyService
      CALL_COUNT = :topology_service_call_count
      CALL_DURATION = :topology_service_call_duration
      BEGIN_UPDATE_COUNT = :topology_service_begin_update_count
      BEGIN_UPDATE_DURATION = :topology_service_begin_update_duration
      BEGIN_UPDATE_CREATE_RECORDS = :topology_service_begin_update_create_records
      BEGIN_UPDATE_DESTROY_RECORDS = :topology_service_begin_update_destroy_records

      class << self
        def add_call(request:, duration:)
          return unless ::Gitlab::SafeRequestStore.active?

          increment(CALL_COUNT, 1)
          increment(CALL_DURATION, duration)

          return unless request.is_a?(::Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest)

          increment(BEGIN_UPDATE_COUNT, 1)
          increment(BEGIN_UPDATE_DURATION, duration)
          increment(BEGIN_UPDATE_CREATE_RECORDS, request.create_records.size)
          increment(BEGIN_UPDATE_DESTROY_RECORDS, request.destroy_records.size)
        end

        def payload
          return {} if value(CALL_COUNT) == 0

          payload = {
            topology_service_calls: value(CALL_COUNT),
            topology_service_duration_s: duration(CALL_DURATION)
          }

          return payload if value(BEGIN_UPDATE_COUNT) == 0

          payload.merge(
            topology_service_begin_update_calls: value(BEGIN_UPDATE_COUNT),
            topology_service_begin_update_duration_s: duration(BEGIN_UPDATE_DURATION),
            topology_service_begin_update_create_records: value(BEGIN_UPDATE_CREATE_RECORDS),
            topology_service_begin_update_destroy_records: value(BEGIN_UPDATE_DESTROY_RECORDS)
          )
        end

        private

        def increment(key, amount)
          ::Gitlab::SafeRequestStore[key] = value(key) + amount
        end

        def value(key)
          ::Gitlab::SafeRequestStore[key] || 0
        end

        def duration(key)
          value(key).round(::Gitlab::InstrumentationHelper::DURATION_PRECISION)
        end
      end
    end
  end
end
