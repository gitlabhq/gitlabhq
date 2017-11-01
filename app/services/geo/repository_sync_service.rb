require 'tmpdir'

module Geo
  class RepositorySyncService < BaseSyncService
    self.type = :repository

    private

    def sync_repository(with_backup = false)
      fetch_project_repository(with_backup)
      expire_repository_caches
    end

    def fetch_project_repository(with_backup)
      log_info('Trying to fetch project repository')
      update_registry(started_at: DateTime.now)

      if with_backup
        log_info('Backup enabled')
        actual_path = project.repository.path_to_repo
        backup_path = File.join(Dir.mktmpdir, project.path)

        # Creating a backup copy and removing the main repo
        FileUtils.mv(actual_path, backup_path)
      end

      project.ensure_repository
      fetch_geo_mirror(project.repository)

      if with_backup
        log_info('Removing backup copy as the repository was redownloaded successfully')
        FileUtils.rm_r(backup_path)
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
      log_info('Expiring caches')
      project.repository.after_create
    ensure
      # Backup can only exist if redownload was unsuccessful
      if with_backup && File.exist?(backup_path)
        FileUtils.mv(backup_path, actual_path)
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
