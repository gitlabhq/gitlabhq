# frozen_string_literal: true

# workflow_ref is populated by Cd::Rollouts::KickoffService after the AutoFlow
# workflow is started on KAS, so a rollout is created (and persisted) before a
# workflow_ref exists. The NOT NULL constraint added in 19.2 contradicts that
# create-then-kickoff flow, so it is removed here.
class RemoveNotNullFromCdRolloutsWorkflowRef < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    remove_not_null_constraint :cd_rollouts, :workflow_ref
  end

  def down
    add_not_null_constraint :cd_rollouts, :workflow_ref
  end
end
