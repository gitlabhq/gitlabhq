# frozen_string_literal: true

class CreateBackgroundOperationJobsCellLocal < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.5'

  disable_ddl_transaction!

  def up
    opts = {
      if_not_exists: true,
      primary_key: [:partition, :id],
      options: 'PARTITION BY LIST (partition)'
    }

    create_table(:background_operation_jobs_cell_local, **opts) do |t|
      t.bigserial :id
      t.bigint :partition, null: false, default: 1
      t.bigint :worker_id, null: false
      t.bigint :worker_partition, null: false
      t.timestamptz :created_at, null: false
      t.timestamptz :started_at
      t.timestamptz :finished_at
      t.integer :batch_size, null: false
      t.integer :sub_batch_size, null: false
      t.integer :pause_ms, null: false, default: 100
      t.integer :status, null: false, default: 0, limit: 2
      t.integer :attempts, null: false, default: 0, limit: 2
      t.jsonb :metrics, null: false, default: {}
      t.jsonb :min_cursor
      t.jsonb :max_cursor
    end

    add_indexes
    add_constraints
  end

  def down
    drop_table(:background_operation_jobs_cell_local, if_exists: true)
  end

  private

  def add_indexes
    add_concurrent_partitioned_index(
      :background_operation_jobs_cell_local,
      :status,
      name: 'index_bj_cell_local_by_status'
    )
  end

  def add_constraints
    add_check_constraint(
      :background_operation_jobs_cell_local,
      "jsonb_typeof(min_cursor) = 'array' AND jsonb_typeof(max_cursor) = 'array'",
      check_constraint_name(:background_operation_jobs_cell_local, 'cursors', 'jsonb_array')
    )

    add_check_constraint(
      :background_operation_jobs_cell_local,
      "pause_ms >= 100",
      check_constraint_name(:background_operation_jobs_cell_local, 'pause_ms', 'minimum_hundred')
    )

    add_check_constraint(
      :background_operation_jobs_cell_local,
      'num_nonnulls(min_cursor, max_cursor) = 2',
      check_constraint_name(:background_operation_jobs_cell_local, 'cursors', 'not_null')
    )
  end
end
