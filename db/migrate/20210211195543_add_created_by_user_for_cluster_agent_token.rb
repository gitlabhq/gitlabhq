# frozen_string_literal: true

class AddCreatedByUserForClusterAgentToken < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_cluster_agent_tokens_on_created_by_user_id'

  disable_ddl_transaction!

  def up
    unless column_exists?(:cluster_agent_tokens, :created_by_user_id)
      add_column :cluster_agent_tokens, :created_by_user_id, :bigint
    end

    add_concurrent_index :cluster_agent_tokens, :created_by_user_id, name: INDEX_NAME
    add_concurrent_foreign_key :cluster_agent_tokens, :users, column: :created_by_user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cluster_agent_tokens, :users, column: :created_by_user_id
    end

    remove_concurrent_index_by_name :cluster_agent_tokens, INDEX_NAME
    remove_column :cluster_agent_tokens, :created_by_user_id
  end
end
