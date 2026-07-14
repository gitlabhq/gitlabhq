# frozen_string_literal: true

class AddNotNullToCdRolloutsWorkflowRef < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_not_null_constraint :cd_rollouts, :workflow_ref
  end

  def down
    remove_not_null_constraint :cd_rollouts, :workflow_ref
  end
end
