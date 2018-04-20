module Ci
  class JobQueuesWorker
    include ApplicationWorker
    include PipelineQueue
  
    queue_namespace :pipeline_processing
    
    def perform(build_id)
      with_exclusive_lease do
        Ci::Build.pending.select(:id).find_each do |build|
          BuildQueueWorker.perform_async_rate_limited(build.id)
        end
      end
    end

    private

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
