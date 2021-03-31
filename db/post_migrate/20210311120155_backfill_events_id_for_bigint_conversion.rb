# frozen_string_literal: true

class BackfillEventsIdForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless Gitlab.dev_env_or_com?

    backfill_conversion_of_integer_to_bigint :events, :id, batch_size: 15000, sub_batch_size: 100
  end

  def down
    return unless Gitlab.dev_env_or_com?

    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(job_class_name: 'CopyColumnUsingBackgroundMigrationJob')
      .where(table_name: 'events', column_name: 'id')
      .where('job_arguments = ?', %w[id id_convert_to_bigint].to_json)
      .delete_all
  end
end
