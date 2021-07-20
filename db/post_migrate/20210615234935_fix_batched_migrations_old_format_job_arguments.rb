# frozen_string_literal: true

class FixBatchedMigrationsOldFormatJobArguments < ActiveRecord::Migration[6.1]
  class BatchedMigration < ActiveRecord::Base
    self.table_name = 'batched_background_migrations'
  end

  def up
    # rubocop:disable Style/WordArray
    [
      ['events', 'id', ['id', 'id_convert_to_bigint'], [['id'], ['id_convert_to_bigint']]],
      ['push_event_payloads', 'event_id', ['event_id', 'event_id_convert_to_bigint'], [['event_id'], ['event_id_convert_to_bigint']]]
    ].each do |table_name, column_name, legacy_job_arguments, current_job_arguments|
      base_scope = BatchedMigration
        .where(job_class_name: 'CopyColumnUsingBackgroundMigrationJob', table_name: table_name, column_name: column_name)
      # rubocop:enable Style/WordArray

      # rubocop:disable Rails/WhereEquals
      base_scope
        .where('job_arguments = ?', legacy_job_arguments.to_json)
        .where('NOT EXISTS (?)', base_scope.select('1').where('job_arguments = ?', current_job_arguments.to_json))
        .update_all(job_arguments: current_job_arguments)
      # rubocop:enable Rails/WhereEquals
    end
  end

  def down
    # No-op, there is no way to know were the existing record migrated from
    # legacy job arguments, or were using the current format from the start.
    # There is no reason to go back anyway.
  end
end
