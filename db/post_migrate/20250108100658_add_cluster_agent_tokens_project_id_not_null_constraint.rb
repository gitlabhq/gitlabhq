# frozen_string_literal: true

class AddClusterAgentTokensProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :cluster_agent_tokens, :project_id
  end

  def down
    remove_not_null_constraint :cluster_agent_tokens, :project_id
  end
end
