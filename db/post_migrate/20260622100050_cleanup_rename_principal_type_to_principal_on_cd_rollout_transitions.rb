# frozen_string_literal: true

class CleanupRenamePrincipalTypeToPrincipalOnCdRolloutTransitions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    cleanup_concurrent_column_rename :cd_rollout_transitions, :principal_type, :principal
  end

  def down
    undo_cleanup_concurrent_column_rename :cd_rollout_transitions, :principal_type, :principal
  end
end
