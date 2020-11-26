# frozen_string_literal: true

class ProjectScheduleBulkRepositoryShardMovesWorker
  include ApplicationWorker

  idempotent!
  feature_category :gitaly
  urgency :throttled

  def perform(source_storage_name, destination_storage_name = nil)
    Projects::ScheduleBulkRepositoryShardMovesService.new.execute(source_storage_name, destination_storage_name)
  end
end
