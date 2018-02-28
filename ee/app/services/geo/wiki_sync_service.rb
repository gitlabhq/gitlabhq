module Geo
  class WikiSyncService < BaseSyncService
    self.type = :wiki

    private

    def sync_repository(redownload = false)
      fetch_wiki_repository(redownload)
    end

    def fetch_wiki_repository(redownload)
      log_info('Fetching wiki repository')
      update_registry!(started_at: DateTime.now)

      if redownload
        log_info('Redownloading wiki')
        fetch_geo_mirror(build_temporary_repository)
        set_temp_repository_as_main
      else
        project.wiki.ensure_repository
        fetch_geo_mirror(project.wiki.repository)
      end

      mark_sync_as_successful
    rescue Gitlab::Git::RepositoryMirroring::RemoteError,
           Gitlab::Shell::Error,
           ProjectWiki::CouldNotCreateWikiError => e
      # In some cases repository does not exists, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfuly downloaded.
      if e.message.include? Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]
        log_info('Repository is not found, marking it as successfully synced')
        mark_sync_as_successful
      else
        fail_registry!('Error syncing wiki repository', e)
      end
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Setting force_to_redownload flag')
      fail_registry!('Invalid wiki', e, force_to_redownload_wiki: true)
    ensure
      clean_up_temporary_repository if redownload
    end

    def ssh_url_to_wiki
      "#{primary_ssh_path_prefix}#{project.full_path}.wiki.git"
    end

    def repository
      project.wiki.repository
    end

    def mark_sync_as_successful
      update_registry!(finished_at: DateTime.now, attrs: { last_wiki_sync_failure: nil })

      log_info('Finished wiki sync',
               update_delay_s: update_delay_in_seconds,
               download_time_s: download_time_in_seconds)
    end

    def retry_count
      registry.public_send("#{type}_retry_count") || -1 # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
