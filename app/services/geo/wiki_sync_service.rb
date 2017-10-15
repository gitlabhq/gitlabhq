module Geo
  class WikiSyncService < BaseSyncService
    self.type = :wiki

    private

    def sync_repository
      fetch_wiki_repository
    end

    def fetch_wiki_repository
      log_info('Fetching wiki repository')
      update_registry(started_at: DateTime.now)

      begin
        project.wiki.ensure_repository
        fetch_geo_mirror(project.wiki.repository)
        update_registry(finished_at: DateTime.now)

        log_info("Finished wiki sync",
                 update_delay_s: update_delay_in_seconds,
                 download_time_s: download_time_in_seconds)
      rescue Gitlab::Git::Repository::NoRepository,
             Gitlab::Git::RepositoryMirroring::RemoteError,
             Gitlab::Shell::Error,
             ProjectWiki::CouldNotCreateWikiError,
             Geo::EmptyCloneUrlPrefixError => e
        log_error('Error syncing wiki repository', e)
      end
    end

    def ssh_url_to_wiki
      "#{primary_ssh_path_prefix}#{project.full_path}.wiki.git"
    end
  end
end
