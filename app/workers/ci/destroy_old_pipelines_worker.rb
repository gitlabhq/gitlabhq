# frozen_string_literal: true

module Ci
  class DestroyOldPipelinesWorker
    include ApplicationWorker
    include CronjobChildWorker
    include LimitedCapacity::Worker

    data_consistency :sticky
    feature_category :continuous_integration
    urgency :low
    idempotent!

    LIMIT = 250
    CONCURRENCY = 10

    def perform_work(*)
      Project.find_by_id(fetch_next_project_id).try do |project|
        with_context(project: project) do
          timestamp = project.ci_delete_pipelines_in_seconds.seconds.ago
          pipelines = Ci::Pipeline.for_project(project.id).created_before(timestamp).limit(LIMIT).to_a

          Ci::DestroyPipelineService.new(project, nil).unsafe_execute(pipelines)

          log_extra_metadata_on_done(:removed_count, pipelines.size)
          log_extra_metadata_on_done(:project, project.full_path)
        end
      end
    end

    def max_running_jobs
      CONCURRENCY
    end

    def remaining_work_count(*)
      Gitlab::Redis::SharedState.with do |redis|
        redis.llen(queue_key)
      end
    end

    private

    def fetch_next_project_id
      Gitlab::Redis::SharedState.with do |redis|
        redis.lpop(queue_key)
      end
    end

    def queue_key
      Ci::ScheduleOldPipelinesRemovalCronWorker::QUEUE_KEY
    end
  end
end
