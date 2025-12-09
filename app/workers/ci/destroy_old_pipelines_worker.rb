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
    RE_ENQUEUE_THRESHOLD = 100
    CONCURRENCY = 10

    def perform_work(*)
      Project.find_by_id(cleanup_queue.fetch_next_project_id!).try do |project|
        with_context(project: project) do
          perform_pipelines_cleanup(project)
        end
      end
    end

    def max_running_jobs
      CONCURRENCY
    end

    def remaining_work_count(*)
      cleanup_queue.size
    end

    private

    def cleanup_queue
      @cleanup_queue ||= Ci::RetentionPolicies::ProjectsCleanupQueue.instance
    end

    def skip_protected_pipelines?(project)
      Feature.enabled?(:ci_skip_old_protected_pipelines, project.root_namespace, type: :wip)
    end

    def skip_locked_pipelines?(project)
      Feature.enabled?(:ci_skip_locked_pipelines, project.root_namespace, type: :wip)
    end

    def perform_pipelines_cleanup(project)
      result = Ci::Pipelines::AutoCleanupService.new(project: project).execute
      payload = result.payload

      destroyed_count = payload[:destroyed_pipelines_size]
      skipped_count = payload[:skipped_pipelines_size]

      cleanup_queue.enqueue!(project) if destroyed_count > RE_ENQUEUE_THRESHOLD ||
        skipped_count > RE_ENQUEUE_THRESHOLD

      log_extra_metadata_on_done(:removed_count, destroyed_count)
      log_extra_metadata_on_done(:skipped_count, skipped_count)
      log_extra_metadata_on_done(:project, project.full_path)
    end
  end
end
