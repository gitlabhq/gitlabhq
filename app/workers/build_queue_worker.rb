class BuildQueueWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  ASYNC_TIMEOUT = 2.hour.to_i

  def perform(build_id)
    Ci::Build.pending.find_by(id: build_id).try do |build|
      Ci::UpdateBuildQueueService.new.execute(build)
    end
  end

  # Don't schedule jobs, again, if they are already were processed recently
  def perform_async_rate_limited(build_id, updated_at)
    lease_key = "ci:build_queue_worker:#{build_id}:updated:#{updated_at}"
    uuid = Gitlab::ExclusiveLease.new(lease_key, timeout: ASYNC_TIMEOUT).try_obtain
    return unless uuid

    super
  rescue => e
    # React only to errors (like Redis)
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
    raise e
  end
end
