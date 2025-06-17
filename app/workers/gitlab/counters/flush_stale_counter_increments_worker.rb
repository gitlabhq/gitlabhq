# frozen_string_literal: true

# Periodically flushes stale counter increments for specific models in batches.
# Tracks progress using Redis to resume from the last processed ID.
# Currently limited to a predefined ID range and ensures only one job runs at a time.
# See: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19461
module Gitlab
  module Counters
    class FlushStaleCounterIncrementsWorker
      include ApplicationWorker
      include LimitedCapacity::Worker

      MAX_RUNNING_JOBS = 1
      BATCH_LIMIT = 1000

      # We hardcoded these IDs here because the FlushCounterIncrementsWorker
      # was disabled in September 2024 after an incident.
      # In March 2025, we reenabled the worker. These are the leftover entries
      # on gitlab.com that still need to be flushed. Afterwards, we can remove this job.
      ID_RANGES = {
        ProjectDailyStatistic => {
          initial_start_id: 3847138140,
          end_id: 4074016739
        }
      }.freeze

      data_consistency :sticky
      feature_category :continuous_integration
      urgency :throttled
      idempotent!
      deduplicate :until_executing
      sidekiq_options retry: true

      def perform_work
        return unless ::Gitlab.com_except_jh? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- we need to check on which instance this happens

        # Process up to 100 batches per job execution as a compromise between
        # performance (avoiding too many small jobs) and efficiency (preventing
        # jobs from running too long and potentially timing out)
        100.times do
          ID_RANGES.each do |model, attributes|
            min_id = start_id(model)
            remaining_work = [(attributes[:end_id] - min_id), 0].max
            last_id = flush_stale_for_model(model, min_id, attributes[:end_id])
            # we need to add +1 here, because otherwise, we'd process the last record twice.
            update_start_id(model, last_id + 1)
            return if remaining_work == 0 # rubocop:disable Lint/NonLocalExitFromIterator -- return if we don't have anymore work to do
          end
        end
      end

      def remaining_work_count
        # iterate through all models and see, if there is still work to do
        remaining_work = 0
        ID_RANGES.each do |model, attributes|
          return remaining_work if remaining_work > 0

          remaining_work = [(attributes[:end_id] - start_id(model)), 0].max
        end
        remaining_work
      end

      def max_running_jobs
        MAX_RUNNING_JOBS
      end

      private

      def flush_stale_for_model(model, min_id, end_id)
        scope = model.where(id: min_id..end_id).order(:id).limit(BATCH_LIMIT) # rubocop:disable CodeReuse/ActiveRecord -- best bet to look for an id > x

        # if we have no records in a batch of 1000 entries, we still need to say, what the next start id could be,
        # so in this case, since we have no id in this case, our best bet would be to use min_id + BATCH_LIMIT to have
        # at least some id to start the next batch from.
        return min_id + BATCH_LIMIT if scope.none?

        Gitlab::Counters::FlushStaleCounterIncrements
          .new(scope)
          .execute

        scope.last.id
      end

      def start_id(model)
        with_redis do |redis|
          (redis.get(redis_key(model)) || ID_RANGES[model][:initial_start_id]).to_i
        end
      end

      def update_start_id(model, start_id)
        with_redis do |redis|
          redis.set(redis_key(model), start_id, ex: 1.week)
        end
      end

      def with_redis(&)
        Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- not AR
      end

      def redis_key(model)
        "flush_stale_counters:last_id:#{model.name}"
      end
    end
  end
end
