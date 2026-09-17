# frozen_string_literal: true

module Gitlab
  module Database
    module PgAsh
      # Calls ash.take_sample() on a fixed cadence for as long as this process
      # holds the lease, so exactly one process in the fleet writes samples.
      #
      # The lease is renewed on every tick rather than held for its full
      # timeout: a bounded loop would leave the schema unsampled between lease
      # holders, which on a single-Sidekiq instance means missing half the
      # samples.
      class Sampler
        include ExclusiveLeaseGuard

        MAX_SAMPLE_INTERVAL = 60

        # Must exceed MAX_SAMPLE_INTERVAL: the lease is only renewed once per
        # tick, so a shorter timeout expires mid-sleep and evicts the holder
        # after every sample.
        LEASE_TIMEOUT = 90.seconds

        # A sample that cannot finish in time is dropped rather than queued.
        # take_sample() traps the cancellation itself, counts it in
        # ash.config.missed_samples and returns -1, so this does not raise.
        STATEMENT_TIMEOUT_MS = 500

        # Give up on the inner loop after this many failures in a row and let
        # the next sampler tick retry, rather than spinning on a broken schema.
        MAX_CONSECUTIVE_ERRORS = 3

        # How often to republish the ash.config counters as gauges.
        STATS_INTERVAL = 30

        METRIC_PREFIX = 'gitlab_pg_ash_'

        # Counters that pg_ash maintains itself. Exported as gauges because the
        # database, not this process, owns the running total.
        CONFIG_COUNTERS = {
          skipped_samples: 'Number of pg_ash samples skipped because sampling was disabled in the database.',
          missed_samples: 'Number of pg_ash samples interrupted before they could be recorded.',
          insert_errors: 'Number of errors pg_ash hit while writing samples.'
        }.freeze

        def initialize(connection = ApplicationRecord.connection)
          @connection = connection
          @lease_key = "pg_ash_sampler:#{connection.load_balancer.name}:lock"
          @consecutive_errors = 0
        end

        # @param continue [Proc] returns false once the calling thread is shutting down
        # @return [void]
        def execute(&continue)
          try_obtain_lease do
            @consecutive_errors = 0

            reconcile_config!
            sample_loop(&continue)
          end

          nil
        rescue StandardError => e
          # Not only ActiveRecordError: an escaped error stops the BaseSampler
          # thread for good, which on a single Sidekiq process ends sampling
          # until a restart. The lease is released; the next tick retries.
          errors_metric.increment
          Gitlab::ErrorTracking.track_exception(e, lease_key: lease_key)

          nil
        end

        private

        attr_reader :connection

        def sample_loop
          last_stats_at = nil

          loop do
            break unless yield && renew_lease!

            unless sampling_enabled?
              # Written back so ash.status() does not report a sampler that
              # no longer runs.
              reconcile_config!
              break
            end

            # A lease can be held for days, so an interval change has to reach
            # ash.config without waiting for the next lease acquisition.
            reconcile_config! if sample_interval != @reconciled_interval

            started_at = Gitlab::Metrics::System.monotonic_time

            break unless take_sample

            if last_stats_at.nil? || (started_at - last_stats_at) >= STATS_INTERVAL
              publish_config_counters
              last_stats_at = started_at
            end

            sleep_until_next_sample(started_at)
          end
        end

        def take_sample
          primary_transaction do
            PgAsh.execute(connection, format("SET LOCAL statement_timeout TO '%dms'", STATEMENT_TIMEOUT_MS))
            PgAsh.execute(connection, "SELECT #{PgAsh::SCHEMA_NAME}.take_sample()")
          end

          @consecutive_errors = 0

          true
        rescue ActiveRecord::ActiveRecordError => e
          @consecutive_errors += 1
          errors_metric.increment

          # Only the give-up is reported; transient blips just bump the counter.
          return true if @consecutive_errors < MAX_CONSECUTIVE_ERRORS

          Gitlab::ErrorTracking.track_exception(e, lease_key: lease_key, consecutive_errors: @consecutive_errors)

          false
        end

        # pg_ash reads sample_interval and sampling_enabled from its own table
        # for its missed-sample bookkeeping, so ash.status() disagrees with
        # reality unless the GitLab settings are written back.
        def reconcile_config!
          interval = sample_interval
          enabled = sampling_enabled? ? 'true' : 'false'

          PgAsh.execute(connection, format(<<~SQL.squish, enabled: enabled, interval: interval))
            UPDATE #{PgAsh::SCHEMA_NAME}.config
            SET sampling_enabled = %<enabled>s, sample_interval = %<interval>d * interval '1 second'
            WHERE singleton
          SQL

          @reconciled_interval = interval
        end

        def publish_config_counters
          row = PgAsh.execute(connection, <<~SQL.squish).first
            SELECT #{CONFIG_COUNTERS.keys.join(', ')}
            FROM #{PgAsh::SCHEMA_NAME}.config
            WHERE singleton
          SQL

          return unless row

          CONFIG_COUNTERS.each_key { |counter| config_gauges[counter].set({}, row[counter.to_s].to_i) }
        end

        # BaseSampler's jitter is deliberately not used here: spacing samples
        # 0.5-1.5s apart would skew the pg_ash per-minute averages.
        def sleep_until_next_sample(started_at)
          elapsed = Gitlab::Metrics::System.monotonic_time - started_at

          Kernel.sleep([sample_interval - elapsed, 0].max)
        end

        def primary_transaction(&block)
          Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer).use_primary do
            connection.transaction(requires_new: false, &block)
          end
        end

        def sample_interval
          Gitlab::CurrentSettings.pg_ash_sample_interval_seconds.to_i.clamp(1, MAX_SAMPLE_INTERVAL)
        end

        def sampling_enabled?
          Gitlab::CurrentSettings.pg_ash_sampling_enabled
        end

        def config_gauges
          @config_gauges ||= CONFIG_COUNTERS.to_h do |counter, description|
            [counter, Gitlab::Metrics.gauge(:"#{METRIC_PREFIX}#{counter}", description, {}, :max)]
          end
        end

        def errors_metric
          @errors_metric ||= Gitlab::Metrics.counter(
            :"#{METRIC_PREFIX}sampler_errors_total",
            'Number of errors raised while taking a pg_ash sample.'
          )
        end

        # Used by ExclusiveLeaseGuard
        def lease_timeout
          LEASE_TIMEOUT
        end

        def lease_taken_log_level
          :info
        end
      end
    end
  end
end
