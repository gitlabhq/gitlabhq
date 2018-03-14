module Geo
  class WikiSyncService < BaseSyncService
    self.type = :wiki

    private

    def sync_repository(redownload = false)
      fetch_repository(redownload)

      mark_sync_as_successful
    rescue Gitlab::Git::RepositoryMirroring::RemoteError,
           Gitlab::Shell::Error,
           ProjectWiki::CouldNotCreateWikiError => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfully downloaded.
      if e.message.include? Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]
        log_info('Wiki repository is not found, marking it as successfully synced')
        mark_sync_as_successful
      else
        fail_registry!('Error syncing wiki repository', e)
      end
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Setting force_to_redownload flag')
      fail_registry!('Invalid wiki', e, force_to_redownload_wiki: true)
    ensure
      clean_up_temporary_repository if redownload
      expire_repository_caches
    end

    def ssh_url_to_wiki
      "#{primary_ssh_path_prefix}#{project.full_path}.wiki.git"
    end

    def repository
      project.wiki.repository
    end

    def ensure_repository
      project.wiki.ensure_repository
    end

    def expire_repository_caches
      log_info('Expiring caches')
      repository.after_sync
    end

    def mark_sync_as_successful
      update_registry!(finished_at: DateTime.now, attrs: { last_wiki_sync_failure: nil })

      log_info('Finished wiki sync',
               update_delay_s: update_delay_in_seconds,
               download_time_s: download_time_in_seconds)
    end
  end
end
