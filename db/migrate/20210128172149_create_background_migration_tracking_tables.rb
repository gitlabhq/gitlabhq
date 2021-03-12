# frozen_string_literal: true

class CreateBackgroundMigrationTrackingTables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table_with_constraints :batched_background_migrations do |t|
      t.timestamps_with_timezone
      t.bigint :min_value, null: false, default: 1
      t.bigint :max_value, null: false
      t.integer :batch_size, null: false
      t.integer :sub_batch_size, null: false
      t.integer :interval, limit: 2, null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.text :job_class_name, null: false
      t.text :batch_class_name, null: false,
        default: 'Gitlab::Database::BackgroundMigration::PrimaryKeyBatchingStrategy'
      t.text :table_name, null: false
      t.text :column_name, null: false
      t.jsonb :job_arguments, null: false, default: '[]'

      t.text_limit :job_class_name, 100
      t.text_limit :batch_class_name, 100
      t.text_limit :table_name, 63
      t.text_limit :column_name, 63

      t.check_constraint :check_positive_min_value, 'min_value > 0'
      t.check_constraint :check_max_value_in_range, 'max_value >= min_value'

      t.check_constraint :check_positive_sub_batch_size, 'sub_batch_size > 0'
      t.check_constraint :check_batch_size_in_range, 'batch_size >= sub_batch_size'

      t.index %i[job_class_name table_name column_name], name: :index_batched_migrations_on_job_table_and_column_name
    end

    create_table :batched_background_migration_jobs do |t|
      t.timestamps_with_timezone
      t.datetime_with_timezone :started_at
      t.datetime_with_timezone :finished_at
      t.references :batched_background_migration, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.bigint :min_value, null: false
      t.bigint :max_value, null: false
      t.integer :batch_size, null: false
      t.integer :sub_batch_size, null: false
      t.integer :status, limit: 2, null: false, default: 0
      t.integer :attempts, limit: 2, null: false, default: 0

      t.index [:batched_background_migration_id, :id], name: :index_batched_jobs_by_batched_migration_id_and_id
    end
  end

  def down
    drop_table :batched_background_migration_jobs

    drop_table :batched_background_migrations
  end
end
