# frozen_string_literal: true

module ObjectPool
  class JoinWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include ObjectPoolQueue

    worker_resource_boundary :cpu

    # The use of pool id is deprecated. Keeping the argument allows old jobs to
    # still be performed.
    def perform(_pool_id, project_id)
      project = Project.find_by_id(project_id)
      return unless project&.pool_repository&.joinable?

      project.link_pool_repository

      Repositories::HousekeepingService.new(project).execute
    end
  end
end
