module Geo
  class ProjectSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :geo, retry: 3, dead: false

    sidekiq_retry_in { |count| 30 * count }

    sidekiq_retries_exhausted do |msg, _|
      Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    end

    def perform(project_id, scheduled_time)
      Geo::RepositorySyncService.new(project_id).execute
    rescue ActiveRecord::RecordNotFound
      logger.error("Couldn't find project with ID=#{project_id}, skipping syncing")
    end
  end
end
