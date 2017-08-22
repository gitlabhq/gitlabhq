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
        project.repository.fetch_geo_mirror(ssh_url_to_repo)

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

    def update_delay_in_seconds
      return unless project.last_repository_updated_at

      (registry.last_repository_successful_sync_at.to_f - project.last_repository_updated_at.to_f).round(3)
    end

    def download_time_in_seconds
      (registry.last_repository_successful_sync_at - registry.last_repository_synced_at).to_f.round(3)
    end
  end
end
