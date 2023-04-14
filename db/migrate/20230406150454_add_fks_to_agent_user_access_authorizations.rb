# frozen_string_literal: true

class AddFksToAgentUserAccessAuthorizations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :agent_user_access_project_authorizations, :projects,
      column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :agent_user_access_project_authorizations, :cluster_agents,
      column: :agent_id, on_delete: :cascade
    add_concurrent_foreign_key :agent_user_access_group_authorizations, :namespaces,
      column: :group_id, on_delete: :cascade
    add_concurrent_foreign_key :agent_user_access_group_authorizations, :cluster_agents,
      column: :agent_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :agent_user_access_project_authorizations, column: :project_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_user_access_project_authorizations, column: :agent_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_user_access_group_authorizations, column: :group_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :agent_user_access_group_authorizations, column: :agent_id
    end
  end
end
