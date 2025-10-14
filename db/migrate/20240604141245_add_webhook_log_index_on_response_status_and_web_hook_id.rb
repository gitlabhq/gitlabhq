# frozen_string_literal: true

class AddWebhookLogIndexOnResponseStatusAndWebHookId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.3'

  TABLE_NAME = :web_hook_logs
  COLUMN_NAMES = [:web_hook_id, :response_status]
  INDEX_NAME = 'web_hook_logs_on_web_hook_id_and_response_status'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/465539
  def up
    prepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end

  def down
    unprepare_partitioned_async_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
  end
end
