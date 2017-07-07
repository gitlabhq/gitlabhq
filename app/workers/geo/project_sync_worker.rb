module Geo
  class ProjectSyncWorker
    include Sidekiq::Worker
    include DedicatedSidekiqQueue

    sidekiq_options retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(project_id, scheduled_time)
      project  = Project.find(project_id)
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)

      Geo::RepositorySyncService.new(project).execute if sync_repository?(registry, scheduled_time)
      Geo::WikiSyncService.new(project).execute if sync_wiki?(registry, scheduled_time)
    rescue ActiveRecord::RecordNotFound
      logger.error("Couldn't find project with ID=#{project_id}, skipping syncing")
    end

    private

    def sync_repository?(registry, scheduled_time)
      !registry.repository_synced_since?(scheduled_time) &&
        registry.resync_repository?
    end

    def sync_wiki?(registry, scheduled_time)
      !registry.wiki_synced_since?(scheduled_time) &&
        registry.resync_wiki?
    end
  end
end
