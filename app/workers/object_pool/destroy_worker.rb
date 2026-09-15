# frozen_string_literal: true

module ObjectPool
  class DestroyWorker
    include ApplicationWorker

    data_consistency :always

    include ObjectPoolQueue

    idempotent!

    sidekiq_retries_exhausted do |job, exception|
      Gitlab::ErrorTracking.track_exception(
        exception,
        pool_repository_id: job['args'][0]
      )
    end

    def perform(pool_repository_id)
      pool = PoolRepository.find_by_id(pool_repository_id)
      return unless pool&.obsolete?

      pool.delete_object_pool
      pool.destroy
    end
  end
end
