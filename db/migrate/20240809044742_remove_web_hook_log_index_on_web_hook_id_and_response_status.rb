# frozen_string_literal: true

class RemoveWebHookLogIndexOnWebHookIdAndResponseStatus < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.4'

  TABLE_NAME = :web_hook_logs
  COLUMN_NAMES = [:web_hook_id, :response_status]
  INDEX_NAME = 'web_hook_logs_on_web_hook_id_and_response_status'

  # Reverting the index added in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048
  def up
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    prepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
