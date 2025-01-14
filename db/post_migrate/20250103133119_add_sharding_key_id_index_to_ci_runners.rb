# frozen_string_literal: true

class AddShardingKeyIdIndexToCiRunners < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.8'

  INDEX_NAME = 'index_ci_runners_on_sharding_key_id_when_not_null'

  def up
    add_concurrent_index :ci_runners, :sharding_key_id, name: INDEX_NAME, where: 'sharding_key_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :ci_runners, :sharding_key_id, name: INDEX_NAME
  end
end
