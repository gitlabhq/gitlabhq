# frozen_string_literal: true

module ObjectPool
  class JoinWorker
    include ApplicationWorker
    include ObjectPoolQueue

    # The use of pool id is deprecated. Keeping the argument allows old jobs to
    # still be performed.
    def perform(_pool_id, project_id)
      project = Project.find_by_id(project_id)
      return unless project&.pool_repository&.joinable?

      project.link_pool_repository

      Projects::HousekeepingService.new(project).execute
    end
  end
end
