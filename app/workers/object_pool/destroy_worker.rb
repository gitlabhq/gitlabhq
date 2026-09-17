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

      # A project can join the pool after it was marked obsolete
      # (https://gitlab.com/gitlab-org/gitlab/-/work_items/628444).
      if pool.member_projects.exists?
        log_extra_metadata_on_done(:destroy_skipped, 'members_exist')

        return
      end

      pool.delete_object_pool
      pool.destroy
    end
  end
end
