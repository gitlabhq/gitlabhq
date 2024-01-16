# frozen_string_literal: true

class BackfillGeoEventLogForBigintConversion < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.8'

  TABLE = :geo_event_log
  COLUMNS = %i[geo_event_id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 200)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
