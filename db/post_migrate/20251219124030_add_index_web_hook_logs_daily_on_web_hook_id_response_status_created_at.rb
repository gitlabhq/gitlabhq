# frozen_string_literal: true

class AddIndexWebHookLogsDailyOnWebHookIdResponseStatusCreatedAt < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.8'

  TABLE_NAME = :web_hook_logs_daily
  COLUMN_NAMES = %i[web_hook_id response_status created_at]
  INDEX_NAME = 'index_web_hook_logs_daily_on_web_hook_id_response_status_created_at'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Read more: https://gitlab.com/gitlab-org/gitlab/-/issues/581494
    prepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
