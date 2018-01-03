module Gitlab
  class SidekiqThrottler
    class << self
      def execute!
        if Gitlab::CurrentSettings.sidekiq_throttling_enabled?
          require 'sidekiq-limit_fetch'

          Gitlab::CurrentSettings.current_application_settings.sidekiq_throttling_queues.each do |queue|
            Sidekiq::Queue[queue].limit = queue_limit
          end
        end
      end

      private

      def queue_limit
        @queue_limit ||=
          begin
            factor = Gitlab::CurrentSettings.current_application_settings.sidekiq_throttling_factor
            (factor * Sidekiq.options[:concurrency]).ceil
          end
      end
    end
  end
end
