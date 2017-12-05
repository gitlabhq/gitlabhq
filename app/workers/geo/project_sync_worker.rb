module Geo
  class ProjectSyncWorker
    include ApplicationWorker

    sidekiq_options retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(project_id, scheduled_time)
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)
      project = registry.project

      if project.nil?
        Gitlab::Geo::Logger.error(class: self.class.name, message: "Couldn't find project, skipping syncing", project_id: project_id)
        return
      end

      Geo::RepositorySyncService.new(project).execute if registry.repository_sync_due?(scheduled_time)
      Geo::WikiSyncService.new(project).execute if registry.wiki_sync_due?(scheduled_time)
    end
  end
end
