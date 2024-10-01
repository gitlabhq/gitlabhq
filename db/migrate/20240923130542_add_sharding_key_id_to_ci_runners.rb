# frozen_string_literal: true

class AddShardingKeyIdToCiRunners < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  enable_lock_retries!

  def up
    add_column :ci_runners, :sharding_key_id, :bigint, null: true, if_not_exists: true
  end

  def down
    remove_column :ci_runners, :sharding_key_id, if_exists: true
  end
end
