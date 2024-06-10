# frozen_string_literal: true

class CreateCiBuildSources < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '17.1'

  def up
    opts = {
      primary_key: [:build_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table :p_ci_build_sources, **opts do |t| # rubocop:disable Migration/EnsureFactoryForTable -- doesn't find partitioned table factory
      t.bigint   :build_id,     null: false
      t.bigint   :partition_id, null: false
      t.bigint   :project_id,   null: false
      t.integer  :source,       null: false, limit: 2

      t.index [:project_id, :build_id]
    end

    add_concurrent_partitioned_foreign_key(
      :p_ci_build_sources, :p_ci_builds,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    drop_table :p_ci_build_sources
  end
end
