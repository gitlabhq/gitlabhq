# frozen_string_literal: true

# The https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144939
# (possibly) resulted in #incident-17655.
# Discussion: https://gitlab.slack.com/archives/C06LDF0H8HL/p1708941520316659 (internal)
# This migration reverts the constraint migration in the original MR.

class RemoveClusterAgentTokensProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    remove_not_null_constraint :cluster_agent_tokens, :project_id
  end

  def down
    add_not_null_constraint :cluster_agent_tokens, :project_id, validate: false
  end
end
