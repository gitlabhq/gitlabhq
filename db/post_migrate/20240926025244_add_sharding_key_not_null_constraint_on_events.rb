# frozen_string_literal: true

class AddShardingKeyNotNullConstraintOnEvents < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  def up
    add_check_constraint :events,
      '(group_id IS NOT NULL) OR (project_id IS NOT NULL) OR (personal_namespace_id IS NOT NULL)',
      :check_events_sharding_key_is_not_null,
      validate: false
  end

  def down
    remove_check_constraint :events, :check_events_sharding_key_is_not_null
  end
end
