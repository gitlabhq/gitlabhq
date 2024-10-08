# frozen_string_literal: true

class AddShardingKeyIdToCiRunnerManagers < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_runner_machines, :sharding_key_id, :bigint, null: true, if_not_exists: true
  end
end
