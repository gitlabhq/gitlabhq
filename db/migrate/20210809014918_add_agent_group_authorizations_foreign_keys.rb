# frozen_string_literal: true

class AddAgentGroupAuthorizationsForeignKeys < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :agent_group_authorizations, :namespaces, column: :group_id
    add_concurrent_foreign_key :agent_group_authorizations, :cluster_agents, column: :agent_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :agent_group_authorizations, column: :group_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_group_authorizations, column: :agent_id
    end
  end
end
