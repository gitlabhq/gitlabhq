# frozen_string_literal: true

module ObjectPool
  class DestroyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include ObjectPoolQueue

    def perform(pool_repository_id)
      pool = PoolRepository.find_by_id(pool_repository_id)
      return unless pool&.obsolete?

      pool.delete_object_pool
      pool.destroy
    end
  end
end
