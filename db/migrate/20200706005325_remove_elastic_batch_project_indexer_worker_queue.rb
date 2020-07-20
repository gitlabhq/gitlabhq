# frozen_string_literal: true

class RemoveElasticBatchProjectIndexerWorkerQueue < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    Sidekiq.redis do |conn|
      conn.del "queue:elastic_batch_project_indexer"
    end
  end
end
