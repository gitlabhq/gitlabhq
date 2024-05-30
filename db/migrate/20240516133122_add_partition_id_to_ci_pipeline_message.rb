# frozen_string_literal: true

class AddPartitionIdToCiPipelineMessage < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column(:ci_pipeline_messages, :partition_id, :bigint, default: 100, null: false)
  end
end
