# frozen_string_literal: true

module ClickHouse
  class RebuildMaterializedViewCronWorker
    include ApplicationWorker
    include ClickHouseWorker
    include Gitlab::ExclusiveLeaseHelpers

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :value_stream_management

    MAX_TTL = 5.minutes
    MAX_RUNTIME = 4.minutes
    REBUILDING_SCHEDULE = 1.week
    MATERIALIZED_VIEW = {
      view_name: 'contributions_mv',
      view_table_name: 'contributions',
      tmp_view_name: 'tmp_contributions_mv',
      tmp_view_table_name: 'tmp_contributions',
      source_table_name: 'events'
    }.freeze

    def self.redis_key
      "rebuild_click_house_materialized_view:#{MATERIALIZED_VIEW[:view_name]}"
    end

    def perform
      return if Feature.disabled?(:rebuild_contributions_mv, type: :gitlab_com_derisk)

      in_lock("#{self.class}:#{MATERIALIZED_VIEW[:view_name]}", ttl: MAX_TTL, retries: 0) do
        state = build_state

        if state[:finished_at] && DateTime.parse(Gitlab::Json.parse(state[:finished_at])) > REBUILDING_SCHEDULE.ago
          break
        end

        service_response = ClickHouse::RebuildMaterializedViewService
          .new(
            connection: ClickHouse::Connection.new(:main),
            runtime_limiter: Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME),
            state: state)
          .execute

        payload = service_response.payload
        current_time = Time.current.to_json
        if payload[:status] == :over_time
          state.merge!(
            next_value: payload[:next_value],
            last_update_at: current_time,
            finished_at: nil
          )
        else
          state.merge!(
            next_value: nil,
            last_update_at: current_time,
            finished_at: current_time,
            started_at: nil
          )
        end

        Gitlab::Redis::SharedState.with do |redis|
          redis.set(self.class.redis_key, Gitlab::Json.dump(state))
        end

        log_extra_metadata_on_done(:state, state)
      end
    end

    private

    def build_state
      Gitlab::Redis::SharedState.with do |redis|
        raw = redis.get(self.class.redis_key)
        state = raw.present? ? Gitlab::Json.parse(raw) : {}
        state.merge(initial_state).symbolize_keys
      end
    end

    def initial_state
      MATERIALIZED_VIEW.merge(started_at: Time.current)
    end
  end
end
