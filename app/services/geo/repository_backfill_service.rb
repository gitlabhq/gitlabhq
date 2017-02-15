module Geo
  class RepositoryBackfillService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        project.create_repository unless project.repository_exists?
        project.repository.after_create if project.empty_repo?
        project.repository.fetch_geo_mirror(ssh_url_to_repo)
        project.repository.expire_all_method_caches
        project.repository.expire_branch_cache
        project.repository.expire_content_cache

        # TODO: Check if it was successful or not
        timestamp = DateTime.now
        registry = Geo::ProjectRegistry.find_or_create_by(project_id: project.id)
        registry.last_repository_synced_at = timestamp
        registry.last_repository_successful_sync_at = timestamp
        registry.save
      end
    end

    private

    def try_obtain_lease
      uuid = Gitlab::ExclusiveLease.new(
        lease_key,
        timeout: 24.hours
      ).try_obtain

      return unless uuid

      yield

      release_lease(uuid)
    end

    def release_lease(uuid)
      Gitlab::ExclusiveLease.cancel(lease_key, uuid)
    end

    def lease_key
      @key ||= "repository_backfill_service:#{project.id}"
    end

    def ssh_url_to_repo
      "#{Gitlab::Geo.primary_ssh_path_prefix}#{project.path_with_namespace}.git"
    end
  end
end
