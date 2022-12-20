# frozen_string_literal: true

class AddPartitionIdToCiSourcesPipelines < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_sources_pipelines, :partition_id, :bigint, default: 100, null: false
  end
end
