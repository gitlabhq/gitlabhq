# frozen_string_literal: true

class CreateIndexWebHookLogsDailyOnHookIdRespStatusCreatedAt < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.10'

  TABLE_NAME = :web_hook_logs_daily
  COLUMN_NAMES = %i[web_hook_id response_status created_at]
  INDEX_NAME = 'idx_web_hook_logs_daily_on_hook_id_resp_status_created_at'

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Read more: https://gitlab.com/gitlab-org/gitlab/-/issues/581494
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
