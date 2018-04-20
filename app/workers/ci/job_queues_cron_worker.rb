module Ci
  class JobQueuesCronWorker
    include ApplicationWorker
    include PipelineQueue
  
    queue_namespace :pipeline_processing
    
    def perform
      with_exclusive_lease do
        all_pending_builds.find_each do |build|
          updated_at = updated_at_of_build(build)

          BuildQueueWorker.perform_async_rate_limited(build.id, updated_at.to_i)
        end
      end
    end

    private

    def all_pending_builds
      Ci::Build.includes(:project).pending
    end

    def updated_at_of_build(build)
      [
        build.project.all_active_runners.maximum(&:updated_at),
        build.project.udated_at
      ].maximum
    end

    def exclusive_lease_key
      "ci:job_queues_worker"
    end

    def with_exclusive_lease
      uuid = Gitlab::ExclusiveLease.new(exclusive_lease_key, timeout: 1.hour.to_i).try_obtain
      raise 'exclusive lease already taken' unless uuid

      yield uuid
    ensure
      Gitlab::ExclusiveLease.cancel(exclusive_lease_key, uuid)
    end
  end
end
