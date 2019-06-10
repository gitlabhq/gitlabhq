# frozen_string_literal: true

module Projects
  class GitDeduplicationService < BaseService
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 86400

    delegate :pool_repository, to: :project
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        unless project.has_pool_repository?
          disconnect_git_alternates
          break
        end

        if source_project? && pool_can_fetch_from_source?
          fetch_from_source
        end

        project.link_pool_repository if same_storage_as_pool?(project.repository)
      end
    end

    private

    def disconnect_git_alternates
      project.repository.disconnect_alternates
    end

    def pool_can_fetch_from_source?
      project.git_objects_poolable? &&
        same_storage_as_pool?(pool_repository.source_project.repository)
    end

    def same_storage_as_pool?(repository)
      pool_repository.object_pool.repository.storage == repository.storage
    end

    def fetch_from_source
      project.pool_repository.object_pool.fetch
    end

    def source_project?
      return unless project.has_pool_repository?

      project.pool_repository.source_project == project
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    def lease_key
      "git_deduplication:#{project.id}"
    end
  end
end
