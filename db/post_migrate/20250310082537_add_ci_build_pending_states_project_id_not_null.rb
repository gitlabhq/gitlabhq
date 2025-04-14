# frozen_string_literal: true

class AddCiBuildPendingStatesProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :ci_build_pending_states, :project_id
  end

  def down
    remove_not_null_constraint :ci_build_pending_states, :project_id
  end
end
