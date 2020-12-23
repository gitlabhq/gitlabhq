# frozen_string_literal: true

class SnippetScheduleBulkRepositoryShardMovesWorker
  include ApplicationWorker

  idempotent!
  feature_category :gitaly
  urgency :throttled

  def perform(source_storage_name, destination_storage_name = nil)
    Snippets::ScheduleBulkRepositoryShardMovesService.new.execute(source_storage_name, destination_storage_name)
  end
end
