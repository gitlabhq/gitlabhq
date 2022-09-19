# frozen_string_literal: true

class AddPartitionIdToCiPipelineVariables < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_pipeline_variables, :partition_id, :bigint, default: 100, null: false
  end
end
