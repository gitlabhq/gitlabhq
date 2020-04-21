# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CleanupOptimisticLockingNullsPt2 < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  TABLES = %w(ci_stages ci_builds ci_pipelines).freeze
  BATCH_SIZE = 10_000

  def declare_class(table)
    Class.new(ActiveRecord::Base) do
      include EachBatch

      self.table_name = table
      self.inheritance_column = :_type_disabled # Disable STI
    end
  end

  def up
    last_table_final_delay = 0

    TABLES.each do |table|
      add_concurrent_index table.to_sym, :lock_version, where: "lock_version IS NULL"

      last_table_final_delay = queue_background_migration_jobs_by_range_at_intervals(
        declare_class(table).where(lock_version: nil),
        'CleanupOptimisticLockingNulls',
        2.minutes,
        batch_size: BATCH_SIZE,
        other_job_arguments: [table],
        initial_delay: last_table_final_delay
      )
    end
  end

  def down
    TABLES.each do |table|
      remove_concurrent_index table.to_sym, :lock_version, where: "lock_version IS NULL"
    end
  end
end
