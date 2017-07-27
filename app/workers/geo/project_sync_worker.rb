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

      Geo::RepositorySyncService.new(project).execute if sync_repository?(registry, scheduled_time)
      Geo::WikiSyncService.new(project).execute if sync_wiki?(registry, scheduled_time)
    rescue ActiveRecord::RecordNotFound => e
      Gitlab::Geo::Logger.error(
        class: self.class.name,
        message: "Couldn't find project, skipping syncing",
        project_id: project_id,
        error: e
      )
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
