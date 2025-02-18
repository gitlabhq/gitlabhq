# frozen_string_literal: true

class ScheduleIndexesToWebHookLogsDaily < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.9'

  TABLE_NAME = :web_hook_logs_daily
  INDEX_NAME_1 = :index_web_hook_logs_daily_on_web_hook_id_and_created_at
  INDEX_NAME_2 = :index_web_hook_logs_daily_part_on_created_at_and_web_hook_id
  COLUMN_NAMES_1 = [:web_hook_id, :created_at]
  COLUMN_NAMES_2 = [:created_at, :web_hook_id]

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/514158
  def up
    prepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES_1, name: INDEX_NAME_1)
    prepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES_2, name: INDEX_NAME_2)
  end

  def down
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES_1, name: INDEX_NAME_1)
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES_2, name: INDEX_NAME_2)
  end
end
