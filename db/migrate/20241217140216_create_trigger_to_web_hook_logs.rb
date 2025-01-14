# frozen_string_literal: true

class CreateTriggerToWebHookLogs < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.8'

  SOURCE_TABLE = :web_hook_logs
  TARGET_TABLE = :web_hook_logs_daily
  UNIQUE_KEY = [:id, :created_at].freeze

  def up
    create_trigger_to_sync_tables(SOURCE_TABLE, TARGET_TABLE, UNIQUE_KEY)
  end

  def down
    drop_sync_trigger(SOURCE_TABLE)
  end
end
