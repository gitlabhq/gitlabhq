module Geo
  class RepositorySyncService < BaseSyncService
    self.type = :repository

    private

    def sync_repository
      fetch_project_repository
      expire_repository_caches
    end

    def fetch_project_repository
      log_info('Fetching project repository')
      update_registry(started_at: DateTime.now)

      begin
        project.ensure_repository
        fetch_geo_mirror(project.repository)
        update_registry(finished_at: DateTime.now)

        log_info("Finished repository sync",
                 update_delay_s: update_delay_in_seconds,
                 download_time_s: download_time_in_seconds)
      rescue Gitlab::Shell::Error, Geo::EmptyCloneUrlPrefixError => e
        log_error('Error syncing repository', e)
      rescue Gitlab::Git::Repository::NoRepository => e
        log_error('Invalid repository', e)
        log_info('Expiring caches')
        project.repository.after_create
      end
    end

    def expire_repository_caches
      log_info('Expiring caches')
      project.repository.after_sync
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.full_path}.git"
    end
  end
end
