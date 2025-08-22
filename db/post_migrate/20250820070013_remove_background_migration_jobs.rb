# frozen_string_literal: true

class RemoveBackgroundMigrationJobs < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  TABLE_NAME = :background_migration_jobs

  def up
    drop_table(TABLE_NAME, if_exists: true)
  end

  def down
    with_lock_retries do
      create_table(TABLE_NAME) do |t|
        t.timestamps_with_timezone null: false
        t.integer :status, limit: 2, null: false, default: 0
        t.text :class_name, null: false
        t.jsonb :arguments, null: false
      end
    end

    add_check_constraint(TABLE_NAME, "char_length(class_name) <= 200", "check_b0de0a5852")

    add_index(TABLE_NAME,
      [:class_name, :arguments],
      name: "index_background_migration_jobs_on_class_name_and_arguments")

    add_index(TABLE_NAME,
      [:class_name, :status, :id],
      name: "index_background_migration_jobs_on_class_name_and_status_and_id")

    add_index(TABLE_NAME,
      "((arguments ->> 2))",
      name: "index_background_migration_jobs_for_partitioning_migrations",
      where: "class_name = 'Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable'::text")
  end
end
