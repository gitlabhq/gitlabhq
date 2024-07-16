# frozen_string_literal: true

class AddAutoCanceledByPartitionIdToCiPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :ci_pipelines, :auto_canceled_by_partition_id, :bigint
  end
end
