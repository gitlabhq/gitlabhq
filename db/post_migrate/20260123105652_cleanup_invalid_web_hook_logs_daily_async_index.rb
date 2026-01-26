# frozen_string_literal: true

class CleanupInvalidWebHookLogsDailyAsyncIndex < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.9'

  TABLE_NAME = :web_hook_logs_daily
  COLUMN_NAMES = %i[web_hook_id response_status created_at]
  OLD_INDEX_NAME = 'index_web_hook_logs_daily_on_web_hook_id_response_status_created_at'

  def up
    # Remove async index with invalid name (68 chars, exceeds PostgreSQL's 63 char limit)
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: OLD_INDEX_NAME)
  end

  def down
    # no-op: intentionally not re-preparing the old index as its name
    # exceeds PostgreSQL's 63 character limit
  end
end
