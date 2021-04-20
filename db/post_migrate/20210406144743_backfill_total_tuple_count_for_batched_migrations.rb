# frozen_string_literal: true

class BackfillTotalTupleCountForBatchedMigrations < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    return unless should_run?

    Gitlab::Database::BackgroundMigration::BatchedMigration.all.each do |migration|
      total_tuple_count = Gitlab::Database::PgClass.for_table(migration.table_name)&.cardinality_estimate

      migration.update(total_tuple_count: total_tuple_count)
    end
  end

  def down
    return unless should_run?

    Gitlab::Database::BackgroundMigration::BatchedMigration.update_all(total_tuple_count: nil)
  end

  private

  def should_run?
    Gitlab.dev_or_test_env? || Gitlab.com?
  end
end
