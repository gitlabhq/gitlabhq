# frozen_string_literal: true

module ObjectPool
  class ScheduleJoinWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include ObjectPoolQueue

    def perform(pool_id)
      pool = PoolRepository.find_by_id(pool_id)
      return unless pool&.joinable?

      pool.member_projects.find_each do |project|
        next if project.forked? && !project.import_finished?

        ObjectPool::JoinWorker.perform_async(pool.id, project.id)
      end
    end
  end
end
