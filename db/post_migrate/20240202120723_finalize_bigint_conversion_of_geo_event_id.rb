# frozen_string_literal: true

class FinalizeBigintConversionOfGeoEventId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  milestone '16.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = 'geo_event_log'
  COLUMN_NAME = 'geo_event_id'
  BIGINT_COLUMN_NAME = 'geo_event_id_convert_to_bigint'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: COLUMN_NAME,
      job_arguments: [[COLUMN_NAME], [BIGINT_COLUMN_NAME]]
    )
  end

  def down
    # no-op
  end
end
