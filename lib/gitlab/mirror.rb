module Gitlab
  module Mirror
    include Gitlab::CurrentSettings

    # Runs scheduler every minute
    SCHEDULER_CRON = '* * * * *'.freeze
    PULL_CAPACITY_KEY = 'MIRROR_PULL_CAPACITY'.freeze
    JITTER = 1.minute
    MIN_DELAY = 15.minutes

    class << self
      def configure_cron_job!
        destroy_cron_job!
        return if Gitlab::Geo.secondary?

        Sidekiq::Cron::Job.create(
          name: 'update_all_mirrors_worker',
          cron: SCHEDULER_CRON,
          class: 'UpdateAllMirrorsWorker'
        )
      end

      def max_mirror_capacity_reached?
        available_capacity <= 0
      end

      def reschedule_immediately?
        available_spots = available_capacity
        return false if available_spots < capacity_threshold

        # Only reschedule if we are able to completely fill up the available spots.
        mirrors_ready_to_sync_count >= available_spots
      end

      def mirrors_ready_to_sync_count
        Project.mirrors_to_sync(Time.now).count
      end

      def available_capacity
        current_capacity = Gitlab::Redis::SharedState.with { |redis| redis.scard(PULL_CAPACITY_KEY) }.to_i

        available = max_capacity - current_capacity
        if available < 0
          Rails.logger.info("Mirror available capacity is below 0: #{available}")
          available = 0
        end

        available
      end

      def increment_capacity(project_id)
        Gitlab::Redis::SharedState.with { |redis| redis.sadd(PULL_CAPACITY_KEY, project_id) }
      end

      # We do not want negative capacity
      def decrement_capacity(project_id)
        Gitlab::Redis::SharedState.with { |redis| redis.srem(PULL_CAPACITY_KEY, project_id) }
      end

      def max_delay
        current_application_settings.mirror_max_delay.minutes + rand(JITTER)
      end

      def min_delay_upper_bound
        MIN_DELAY + JITTER
      end

      def min_delay
        MIN_DELAY + rand(JITTER)
      end

      def max_capacity
        current_application_settings.mirror_max_capacity
      end

      def capacity_threshold
        current_application_settings.mirror_capacity_threshold
      end

      private

      def update_all_mirrors_cron_job
        Sidekiq::Cron::Job.find("update_all_mirrors_worker")
      end

      def destroy_cron_job!
        update_all_mirrors_cron_job&.destroy
      end
    end
  end
end
