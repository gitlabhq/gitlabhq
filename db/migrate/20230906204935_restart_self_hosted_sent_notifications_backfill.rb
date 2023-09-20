# frozen_string_literal: true

class RestartSelfHostedSentNotificationsBackfill < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE = :sent_notifications
  COLUMNS = %i[id]

  def up
    return if should_skip? || id_is_bigint? || already_backfilled?

    # rubocop: disable Migration/BatchMigrationsPostOnly
    delete_batched_background_migration(
      'CopyColumnUsingBackgroundMigrationJob',
      :sent_notifications,
      :id,
      [["id"], ["id_convert_to_bigint"]]
    )
    # rubocop: enable Migration/BatchMigrationsPostOnly

    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    return if should_skip? || id_is_bigint? || already_backfilled?

    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def should_skip?
    com_or_dev_or_test_but_not_jh?
  end

  def id_is_bigint?
    table_columns = columns(TABLE)
    column_id = table_columns.find { |c| c.name == 'id' }
    column_id.sql_type == 'bigint'
  end

  def already_backfilled?
    res = connection.execute <<~SQL
      SELECT
          id_convert_to_bigint
      FROM
          sent_notifications
      ORDER BY
          id ASC
      LIMIT 1
    SQL
    return false if res.ntuples == 0

    res.first['id_convert_to_bigint'].to_i != 0
  end
end
