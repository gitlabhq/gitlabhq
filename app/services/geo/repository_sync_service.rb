module Geo
  class RepositorySyncService < BaseSyncService
    include Gitlab::ShellAdapter

    self.type = :repository

    private

    def sync_repository(redownload = false)
      fetch_project_repository(redownload)
      expire_repository_caches
    end

    def fetch_project_repository(redownload)
      log_info('Trying to fetch project repository')
      update_registry(started_at: DateTime.now)

      if redownload
        log_info('Redownloading repository')
        fetch_geo_mirror(build_temporary_repository)
        set_temp_repository_as_main
      else
        project.ensure_repository
        fetch_geo_mirror(project.repository)
      end

      update_registry(finished_at: DateTime.now)
      log_info('Finished repository sync',
               update_delay_s: update_delay_in_seconds,
               download_time_s: download_time_in_seconds)
    rescue Gitlab::Shell::Error,
           Gitlab::Git::RepositoryMirroring::RemoteError,
           Geo::EmptyCloneUrlPrefixError => e
      log_error('Error syncing repository', e)
    rescue Gitlab::Git::Repository::NoRepository => e
      log_error('Invalid repository', e)
      log_info('Setting force_to_redownload flag')
      registry.update(force_to_redownload_repository: true)
      log_info('Expiring caches')
      project.repository.after_create
    ensure
      clean_up_temporary_repository if redownload
    end

    def expire_repository_caches
      log_info('Expiring caches')
      project.repository.after_sync
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.full_path}.git"
    end

    def repository
      project.repository
    end
  end
end
