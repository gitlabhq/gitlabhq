# frozen_string_literal: true

class CreatePipelineIidsHashPartitionedTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!

  milestone '18.7'

  TABLE_NAME = :p_ci_pipeline_iids

  def up
    create_table TABLE_NAME, if_not_exists: true, options: 'PARTITION BY HASH (project_id)',
      primary_key: [:project_id, :iid] do |t|
      t.bigint :project_id, null: false
      t.integer :iid, null: false
    end

    create_hash_partitions(TABLE_NAME, 64)
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
