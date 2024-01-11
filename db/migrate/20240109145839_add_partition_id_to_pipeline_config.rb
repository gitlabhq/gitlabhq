# frozen_string_literal: true

class AddPartitionIdToPipelineConfig < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  def change
    add_column(:ci_pipelines_config, :partition_id, :bigint, default: 100, null: false)
  end
end
