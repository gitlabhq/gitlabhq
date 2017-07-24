module Geo
  class RepositorySyncService < BaseSyncService
    self.type = :repository

    private

    def sync_repository
      fetch_project_repository
      expire_repository_caches
    end

    def fetch_project_repository
      log('Fetching project repository')
      update_registry(:repository, started_at: DateTime.now)

      begin
        project.ensure_repository
        project.repository.fetch_geo_mirror(ssh_url_to_repo)

        update_registry(:repository, finished_at: DateTime.now)
      rescue Gitlab::Shell::Error, Geo::EmptyCloneUrlPrefixError => e
        Rails.logger.error("#{self.class.name}: Error syncing repository for project #{project.path_with_namespace}: #{e}")
      rescue Gitlab::Git::Repository::NoRepository => e
        Rails.logger.error("#{self.class.name}: Error invalid repository for project #{project.path_with_namespace}: #{e}")
        log('Expiring caches')
        project.repository.after_create
      end
    end

    def expire_repository_caches
      log('Expiring caches')
      project.repository.after_sync
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.path_with_namespace}.git"
    end
  end
end
