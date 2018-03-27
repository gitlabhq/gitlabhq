module Geo
  class ProjectSyncWorker
    include ApplicationWorker
    include GeoQueue
    include Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(project_id, scheduled_time)
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)
      project = registry.project

      if project.nil?
        log_error("Couldn't find project, skipping syncing", project_id: project_id)
        return
      end

      mark_disabled_wiki_as_synced(registry)

      Geo::RepositorySyncService.new(project).execute if registry.repository_sync_due?(scheduled_time)
      Geo::WikiSyncService.new(project).execute if registry.wiki_sync_due?(scheduled_time)
    end

    private

    def mark_disabled_wiki_as_synced(registry)
      return if registry.project.wiki_enabled?

      registry.last_wiki_sync_failure = nil
      registry.resync_wiki = false
      registry.wiki_retry_count = nil
      registry.wiki_retry_at = nil
      registry.force_to_redownload_wiki = false

      if registry.changed? || registry.last_wiki_synced_at.nil? || registry.last_wiki_successful_sync_at.nil?
        registry.last_wiki_synced_at = DateTime.now
        registry.last_wiki_successful_sync_at = DateTime.now

        success = registry.save
        log_info("#{success ? 'Successfully marked' : 'Failed to mark'} disabled wiki as synced", registry_id: registry.id, project_id: registry.project_id)
      end
    end
  end
end
