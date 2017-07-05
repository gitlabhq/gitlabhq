module Geo
  class ProjectSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :geo, retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(project_id, scheduled_time)
      project  = Project.find(project_id)
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)

      Geo::RepositorySyncService.new(project).execute if sync_repository?(registry)
      Geo::WikiSyncService.new(project).execute if sync_wiki?(registry)
    rescue ActiveRecord::RecordNotFound
      logger.error("Couldn't find project with ID=#{project_id}, skipping syncing")
    end

    private

    def sync_repository?(registry)
      registry.resync_repository? ||
        registry.last_repository_successful_sync_at.nil? ||
        registry.last_repository_synced_at.nil?
    end

    def sync_wiki?(registry)
      registry.resync_wiki? ||
        registry.last_wiki_successful_sync_at.nil? ||
        registry.last_wiki_synced_at.nil?
    end
  end
end
