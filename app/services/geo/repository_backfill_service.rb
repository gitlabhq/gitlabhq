module Geo
  class RepositoryBackfillService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        synchronize do |started_at, finished_at|
          registry = Geo::ProjectRegistry.find_or_create_by(project_id: project.id)
          registry.last_repository_synced_at = started_at
          registry.last_repository_successful_sync_at = finished_at if finished_at
          registry.save
        end
      end
    end

    private

    def synchronize
      started_at  = DateTime.now
      finished_at = nil

      begin
        project.create_repository unless project.repository_exists?
        project.repository.after_create if project.empty_repo?
        project.repository.fetch_geo_mirror(ssh_url_to_repo)
        project.repository.expire_all_method_caches
        project.repository.expire_branch_cache
        project.repository.expire_content_cache

        finished_at = DateTime.now
      rescue Gitlab::Shell::Error => e
        Rails.logger.error("Error backfilling repository #{project.path_with_namespace}: #{e}")
      end

      yield started_at, finished_at
    end

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
