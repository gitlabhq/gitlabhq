module Geo
  class WikiSyncService < BaseSyncService
    self.type = :wiki

    private

    def sync_repository
      fetch_wiki_repository
    end

    def fetch_wiki_repository
      log_info('Fetching wiki repository')
      start_time = DateTime.now
      update_registry(started_at: start_time)

      begin
        project.wiki.ensure_repository
        project.wiki.repository.fetch_geo_mirror(ssh_url_to_wiki)

        finish_time = DateTime.now
        log_info("Finished wiki sync",
                 update_delay_s: update_delay(finish_time),
                 download_time_s: (finish_time - start_time).to_f.round(3))
        update_registry(finished_at: DateTime.now)
      rescue Gitlab::Git::Repository::NoRepository,
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
