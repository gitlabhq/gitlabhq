# frozen_string_literal: true

module Ci
  class ScheduleOldPipelinesRemovalCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- does not perform work scoped to a context

    urgency :low
    idempotent!
    deduplicate :until_executed, including_scheduled: true
    feature_category :continuous_integration
    data_consistency :sticky

    PROJECTS_LIMIT = 1_000
    LAST_PROCESSED_REDIS_KEY = 'ci_old_pipelines_removal_last_processed_project_id{}'
    REDIS_EXPIRATION_TIME = 2.hours.to_i
    QUEUE_KEY = 'ci_old_pipelines_removal_project_ids_queue{}'

    def perform
      limit = PROJECTS_LIMIT - queued_entries_count
      project_ids = fetch_next_project_ids(limit)
      queue_projects_for_processing(project_ids)
      remove_last_processed_id if project_ids.empty? || project_ids.size < limit

      Ci::DestroyOldPipelinesWorker.perform_with_capacity
    end

    private

    def fetch_next_project_ids(limit)
      ProjectCiCdSetting
        .configured_to_delete_old_pipelines
        .for_project(last_processed_id..)
        .order_project_id_asc
        .pluck_project_id(limit)
    end

    def queued_entries_count
      with_redis do |redis|
        redis.llen(QUEUE_KEY).to_i
      end
    end

    def queue_projects_for_processing(ids)
      return if ids.empty?

      with_redis do |redis|
        redis.pipelined do |pipeline|
          pipeline.rpush(QUEUE_KEY, ids)
          pipeline.set(LAST_PROCESSED_REDIS_KEY, ids.last, ex: REDIS_EXPIRATION_TIME)
        end
      end
    end

    def last_processed_id
      with_redis do |redis|
        redis.get(LAST_PROCESSED_REDIS_KEY).to_i
      end
    end

    def remove_last_processed_id
      with_redis do |redis|
        redis.del(LAST_PROCESSED_REDIS_KEY)
      end
    end

    def with_redis(&)
      Gitlab::Redis::SharedState.with(&) # rubocop:disable CodeReuse/ActiveRecord -- not AR
    end
  end
end
