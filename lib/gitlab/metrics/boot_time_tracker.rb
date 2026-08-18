# frozen_string_literal: true

module Gitlab
  module Metrics
    class BootTimeTracker
      include Singleton

      SUPPORTED_RUNTIMES = [:puma, :sidekiq, :console].freeze

      def startup_time
        @startup_time || 0
      end

      def track_boot_time!(logger: Gitlab::AppJsonLogger)
        return if @startup_time

        runtime = Gitlab::Runtime.safe_identify
        return unless SUPPORTED_RUNTIMES.include?(runtime)

        @startup_time = Gitlab::Metrics::System.process_runtime_elapsed_seconds

        Gitlab::Metrics.gauge(
          :gitlab_rails_boot_time_seconds, 'Time elapsed for Rails primary process to finish startup'
        ).set({}, @startup_time)

        log_payload = { message: 'Application boot finished', runtime: runtime.to_s, duration_s: @startup_time }
        log_payload.merge!(bootsnap_compile_cache_stats) if Gitlab::BootsnapCacheStore.enabled?

        logger.info(**log_payload)
      end

      def reset!
        @startup_time = nil
      end

      private

      # Reports the Bootsnap compile cache hit rate observed during boot.
      #
      # The counts barely change once the application has booted (in production
      # everything is eager-loaded), so reporting once here is enough and avoids
      # a dedicated sampler thread. We log the ratio in addition to exposing a
      # counter because a log line is captured even when a metrics scrape is
      # missed, e.g. for a slow or short-lived process (CI) - exactly the case
      # where a cold cache is most likely.
      #
      # Log fields are flat, dotted keys (rather than a nested hash) so they map
      # cleanly to individual fields in Kibana. The logged hit ratio is a
      # percentage rounded to the nearest integer; the raw counts in the counter
      # allow the exact ratio to be computed in PromQL.
      def bootsnap_compile_cache_stats
        counts = Gitlab::BootsnapCacheStore.counts

        counter = Gitlab::Metrics.counter(
          :gitlab_bootsnap_compile_cache_events_total,
          'Number of Bootsnap compile cache events observed during boot, by type'
        )
        counts.each { |event, count| counter.increment({ event: event.to_s }, count) }

        # Derive the ratio from the same snapshot as the counts above so the
        # logged counts and ratio can never disagree.
        ratio = Gitlab::BootsnapCacheStore.hit_ratio(counts)

        {
          'bootsnap.hit': counts[:hit],
          'bootsnap.revalidated': counts[:revalidated],
          'bootsnap.miss': counts[:miss],
          'bootsnap.stale': counts[:stale],
          'bootsnap.hit_ratio': ratio && (ratio * 100).round
        }
      end
    end
  end
end
