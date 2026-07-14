# frozen_string_literal: true

class RemoveFkFromCdEnvironmentsOnClusterAgentId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :cd_environments
  FK_NAME = :fk_54d43a716a

  def up
    return unless table_exists?(TABLE_NAME)

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :cluster_agents, column: :cluster_agent_id, name: FK_NAME
    end
  end

  def down
    return unless table_exists?(TABLE_NAME)
    return unless table_exists?(:cluster_agents)

    add_concurrent_foreign_key TABLE_NAME, :cluster_agents,
      column: :cluster_agent_id, on_delete: :restrict, name: FK_NAME
  end
end
