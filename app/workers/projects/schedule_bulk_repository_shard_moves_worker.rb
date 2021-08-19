# frozen_string_literal: true

module Projects
  class ScheduleBulkRepositoryShardMovesWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    feature_category :gitaly
    urgency :throttled

    def perform(source_storage_name, destination_storage_name = nil)
      Projects::ScheduleBulkRepositoryShardMovesService.new.execute(source_storage_name, destination_storage_name)
    end
  end
end
