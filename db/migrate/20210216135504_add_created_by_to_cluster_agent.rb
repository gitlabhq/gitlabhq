# frozen_string_literal: true

class AddCreatedByToClusterAgent < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_cluster_agents_on_created_by_user_id'

  disable_ddl_transaction!

  def up
    unless column_exists?(:cluster_agents, :created_by_user_id)
      with_lock_retries do
        add_column :cluster_agents, :created_by_user_id, :bigint
      end
    end

    add_concurrent_index :cluster_agents, :created_by_user_id, name: INDEX_NAME
    add_concurrent_foreign_key :cluster_agents, :users, column: :created_by_user_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_column :cluster_agents, :created_by_user_id
    end
  end
end
