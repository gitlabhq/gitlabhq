module Geo
  class WikiSyncService < BaseSyncService
    self.type = :wiki

    private

    def sync_repository(with_backup = false)
      fetch_wiki_repository(with_backup)
    end

    def fetch_wiki_repository(with_backup)
      log_info('Fetching wiki repository')
      update_registry(started_at: DateTime.now)

      if with_backup
        log_info('Backup enabled')
        actual_path = project.wiki.path_to_repo
        backup_path = File.join(Dir.mktmpdir, 'wiki')

        # Creating a backup copy and removing the main wiki
        FileUtils.mv(actual_path, backup_path)
      end

      project.wiki.ensure_repository
      fetch_geo_mirror(project.wiki.repository)

      if with_backup
        log_info('Removing backup copy as the repository was redownloaded successfully')
        FileUtils.rm_r(backup_path)
      end

      update_registry(finished_at: DateTime.now)

      log_info('Finished wiki sync',
               update_delay_s: update_delay_in_seconds,
               download_time_s: download_time_in_seconds)
    rescue Gitlab::Git::Repository::NoRepository,
           Gitlab::Git::RepositoryMirroring::RemoteError,
           Gitlab::Shell::Error,
           ProjectWiki::CouldNotCreateWikiError,
           Geo::EmptyCloneUrlPrefixError => e
      log_error('Error syncing wiki repository', e)
    ensure
      # Backup can only exist if redownload was unsuccessful
      if with_backup && File.exist?(backup_path)
        FileUtils.mv(backup_path, actual_path)
      end
    end

    def fetch_wiki_repository_with_backup
      # TODO: replace with actual implementation
      fetch_wiki_repository
    end

    def ssh_url_to_wiki
      "#{primary_ssh_path_prefix}#{project.full_path}.wiki.git"
    end
  end
end
