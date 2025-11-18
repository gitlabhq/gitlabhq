# frozen_string_literal: true

class AddShardingKeyTriggerToAbuseReports < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  TABLE_NAME = :abuse_reports
  SHARDING_KEY = :organization_id
  PARENT_TABLE = :users
  PARENT_SHARDING_KEY = :organization_id
  FOREIGN_KEY = :reporter_id

  def up
    install_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY,
      foreign_key: FOREIGN_KEY
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY,
      foreign_key: FOREIGN_KEY
    )
  end
end
