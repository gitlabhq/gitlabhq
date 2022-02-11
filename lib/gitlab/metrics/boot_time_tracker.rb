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

        logger.info(message: 'Application boot finished', runtime: runtime.to_s, duration_s: @startup_time)
      end

      def reset!
        @startup_time = nil
      end
    end
  end
end
