# frozen_string_literal: true

module ObjectPool
  class JoinWorker
    include ApplicationWorker
    include ObjectPoolQueue

    def perform(pool_id, project_id)
      pool = PoolRepository.find_by_id(pool_id)
      return unless pool&.joinable?

      project = Project.find_by_id(project_id)
      return unless project

      pool.link_repository(project.repository)

      Projects::HousekeepingService.new(project).execute
    end
  end
end
