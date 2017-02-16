module Geo
  class RepositoryBackfillService
    attr_reader :project

    LEASE_TIMEOUT = 8.hours.freeze

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        fetch_repositories do |started_at, finished_at|
          registry = Geo::ProjectRegistry.find_or_create_by(project_id: project.id)
          registry.last_repository_synced_at = started_at
          registry.last_repository_successful_sync_at = finished_at if finished_at
          registry.save
        end
      end
    end

    private

    def fetch_repositories
      started_at  = DateTime.now
      finished_at = nil

      begin
        project.create_repository unless project.repository_exists?
        project.repository.after_create if project.empty_repo?
        project.repository.fetch_geo_mirror(ssh_url_to_repo)

        # Second .wiki call returns a Gollum::Wiki, and it will always create the physical repository when not found
        if project.wiki_enabled? && project.wiki.wiki.exist?
          project.wiki.repository.fetch_geo_mirror(ssh_url_to_wiki)
        end

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
      uuid = Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT).try_obtain

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

    def primary_ssh_path_prefix
      Gitlab::Geo.primary_ssh_path_prefix
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.path_with_namespace}.git"
    end

    def ssh_url_to_wiki
      "#{primary_ssh_path_prefix}#{project.path_with_namespace}.wiki.git"
    end
  end
end
