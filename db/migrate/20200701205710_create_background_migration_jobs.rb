# frozen_string_literal: true

class CreateBackgroundMigrationJobs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:background_migration_jobs)
      create_table :background_migration_jobs do |t|
        t.timestamps_with_timezone
        t.integer :status, null: false, limit: 2, default: 0
        t.text :class_name, null: false
        t.jsonb :arguments, null: false

        t.index [:class_name, :arguments]
        t.index [:class_name, :status, :id]
      end
    end

    add_text_limit :background_migration_jobs, :class_name, 200
  end

  def down
    drop_table :background_migration_jobs
  end
end
