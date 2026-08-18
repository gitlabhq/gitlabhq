# frozen_string_literal: true

module Gitlab
  # Dependency-free, thread-safe tally of Bootsnap compile cache events.
  #
  # The instrumentation callback that feeds this store is installed very early
  # during boot (see config/boot.rb), before Rails, Zeitwerk or the Prometheus
  # client are available, so this file must not reference any of them.
  # Gitlab::Metrics::BootTimeTracker later publishes these counts as a Prometheus
  # gauge and logs the hit rate once boot finishes.
  #
  # This lives directly under Gitlab (not Gitlab::Metrics) on purpose: the early
  # `require` in config/boot.rb defines its namespace before Zeitwerk is set up,
  # and Gitlab::Metrics is an explicit Zeitwerk namespace (lib/gitlab/metrics.rb
  # defines methods on it). Defining it early would stop Zeitwerk from loading
  # that file, breaking Gitlab::Metrics.client and friends. Gitlab itself is
  # loaded explicitly via `require_dependency` in config/application.rb, so
  # pre-defining it here is safe.
  #
  # See https://github.com/Shopify/bootsnap for the event semantics:
  #   - :hit         served valid compiled output from the cache
  #   - :revalidated cache was re-checked (mtime changed) but content matched,
  #                  so the compiled output was reused
  #   - :miss        no cache entry existed, had to compile
  #   - :stale       cache entry existed but was invalid, had to recompile
  #
  # :hit and :revalidated avoid a recompilation; :miss and :stale do not.
  module BootsnapCacheStore
    EVENTS = %i[hit revalidated miss stale].freeze

    MUTEX = Mutex.new unless defined?(MUTEX)

    # Guarded with `||=` so that state survives if this file is ever loaded
    # more than once (e.g. via the early require in config/boot.rb and again
    # through Zeitwerk, possibly under a different symlinked path).
    @counts ||= Hash.new(0)
    @enabled ||= false

    class << self
      # Called from config/boot.rb to signal that the instrumentation callback
      # was installed. Used to avoid emitting always-zero metrics when Bootsnap
      # is disabled (e.g. the production default).
      def enable!
        MUTEX.synchronize { @enabled = true }
      end

      def enabled?
        MUTEX.synchronize { @enabled }
      end

      def increment(event)
        MUTEX.synchronize { @counts[event] += 1 }
      end

      # Returns a snapshot of cumulative counts for every known event.
      #
      # Uses plain Ruby (not ActiveSupport's `index_with`) to keep this file
      # loadable during early boot, before ActiveSupport is available.
      def counts
        MUTEX.synchronize do
          EVENTS.each_with_object({}) { |event, hash| hash[event] = @counts[event] } # rubocop:disable Rails/IndexWith -- must stay dependency-free
        end
      end

      # Fraction of compile cache lookups that avoided a recompilation
      # (`hit` + `revalidated`). Returns nil when no events were recorded.
      #
      # Accepts an optional counts snapshot so a caller that already fetched
      # `counts` can derive the ratio from the exact same snapshot, rather than
      # taking a second (possibly inconsistent) one.
      def hit_ratio(snapshot = counts)
        total = snapshot.values.sum
        return if total == 0

        hits = snapshot[:hit] + snapshot[:revalidated]
        hits.to_f / total
      end

      def reset!
        MUTEX.synchronize do
          @counts = Hash.new(0)
          @enabled = false
        end
      end
    end
  end
end
