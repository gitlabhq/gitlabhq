# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class Authz
      STATS = :authz_stats
      PROJECT_ACCESS_SOURCE = :authz_project_access_source
      PRIMARY_DURATION = ::Gitlab::Metrics::Subscribers::ActiveRecord.compose_metric_key(:duration_s, :primary)
      REPLICA_DURATION = ::Gitlab::Metrics::Subscribers::ActiveRecord.compose_metric_key(:duration_s, :replica)

      class << self
        # Measures the block unless it runs inside another measured block.
        #
        # @return the block's result
        def measure
          return yield unless ::Gitlab::SafeRequestStore.active?

          store = ::Gitlab::SafeRequestStore.store
          stats = (store[STATS] ||= { depth: 0, calls: 0, duration: 0.0, db_count: 0, db_cached_count: 0,
                                      db_duration: 0.0 })
          return yield if stats[:depth] > 0

          stats[:depth] = 1
          measuring = true
          time = ::Gitlab::Metrics::System.monotonic_time
          db_count = store[:db_count].to_i
          db_cached_count = store[:db_cached_count].to_i
          db_duration = store[PRIMARY_DURATION].to_f + store[REPLICA_DURATION].to_f

          yield
        ensure
          if measuring
            stats[:depth] = 0
            stats[:calls] += 1
            stats[:duration] += ::Gitlab::Metrics::System.monotonic_time - time
            stats[:db_count] += store[:db_count].to_i - db_count
            stats[:db_cached_count] += store[:db_cached_count].to_i - db_cached_count
            stats[:db_duration] += store[PRIMARY_DURATION].to_f + store[REPLICA_DURATION].to_f - db_duration
          end
        end

        # Records which source project access was resolved from. Memberships wins when a request uses both.
        #
        # @param from_memberships [Boolean]
        # @return [void]
        def record_project_access_source(from_memberships)
          return unless ::Gitlab::SafeRequestStore.active?

          store = ::Gitlab::SafeRequestStore.store
          store[PROJECT_ACCESS_SOURCE] = 'memberships' if from_memberships
          store[PROJECT_ACCESS_SOURCE] ||= 'project_authorizations'

          nil
        end

        # `authz_db_count` includes cached queries, like the request's `db_count`.
        def payload
          stats = ::Gitlab::SafeRequestStore[STATS]
          return {} unless stats && stats[:calls] > 0

          {
            authz_call_count: stats[:calls],
            authz_duration_s: stats[:duration].round(6),
            authz_db_count: stats[:db_count],
            authz_db_cached_count: stats[:db_cached_count],
            authz_db_duration_s: stats[:db_duration].round(6),
            authz_project_access_source: ::Gitlab::SafeRequestStore[PROJECT_ACCESS_SOURCE]
          }.compact
        end
      end
    end
  end
end
