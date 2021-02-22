# frozen_string_literal: true

module Projects
  # Tries to schedule a move for every project with repositories on the source shard
  class ScheduleBulkRepositoryShardMovesService
    include ScheduleBulkRepositoryShardMovesMethods
    extend ::Gitlab::Utils::Override

    private

    override :repository_klass
    def repository_klass
      ProjectRepository
    end

    override :container_klass
    def container_klass
      Project
    end

    override :container_column
    def container_column
      :project_id
    end

    override :schedule_bulk_worker_klass
    def self.schedule_bulk_worker_klass
      ::Projects::ScheduleBulkRepositoryShardMovesWorker
    end
  end
end
