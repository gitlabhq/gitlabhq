# frozen_string_literal: true

class BackfillEventsIdForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    return unless should_run?

    backfill_conversion_of_integer_to_bigint :events, :id, batch_size: 15000, sub_batch_size: 100
  end

  def down
    return unless should_run?

    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(job_class_name: 'CopyColumnUsingBackgroundMigrationJob')
      .where(table_name: 'events', column_name: 'id')
      .where(job_arguments: Gitlab::Json.dump(%w[id id_convert_to_bigint]))
      .delete_all
  end

  private

  def should_run?
    Gitlab.dev_or_test_env? || Gitlab.com?
  end
end
