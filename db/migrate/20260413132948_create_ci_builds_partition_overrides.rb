# frozen_string_literal: true

class CreateCiBuildsPartitionOverrides < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '19.0'
  skip_require_disable_ddl_transactions!

  TABLE_NAME = :p_ci_builds_partition_overrides

  def up
    create_table(TABLE_NAME, id: false, options: 'PARTITION BY HASH (build_id)') do |t|
      t.bigint :build_id, primary_key: true, null: false, default: nil
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false, index: true
    end

    create_hash_partitions(TABLE_NAME, 3)
  end

  def down
    drop_table TABLE_NAME
  end
end
