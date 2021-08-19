# frozen_string_literal: true

module ObjectPool
  class CreateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include ObjectPoolQueue
    include ExclusiveLeaseGuard

    attr_reader :pool

    def perform(pool_id)
      @pool = PoolRepository.find_by_id(pool_id)
      return unless pool

      try_obtain_lease do
        perform_pool_creation
      end
    end

    private

    def perform_pool_creation
      return unless pool.failed? || pool.scheduled?

      # If this is a retry and the previous execution failed, deletion will
      # bring the pool back to a pristine state
      pool.delete_object_pool if pool.failed?

      pool.create_object_pool
      pool.mark_ready
    rescue StandardError => e
      pool.mark_failed
      raise e
    end

    def lease_key
      "object_pool:create:#{pool.id}"
    end

    def lease_timeout
      1.hour
    end
  end
end
