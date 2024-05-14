# frozen_string_literal: true

class AddClusterAgentTokensProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :cluster_agent_tokens, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :cluster_agent_tokens, :project_id
  end
end
