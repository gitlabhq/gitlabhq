module Gitlab
  class SidekiqThrottler
    class << self
      def execute!
        if Gitlab::CurrentSettings.sidekiq_throttling_enabled?
          current_application_settings.sidekiq_throttling_queues.each do |queue|
            Sidekiq::Queue[queue].limit = set_limit
          end
        end
      end

      private

      def set_limit
        factor = current_application_settings.sidekiq_throttling_factor

        (factor * Sidekiq.options[:concurrency]).ceil
      end
    end
  end
end
