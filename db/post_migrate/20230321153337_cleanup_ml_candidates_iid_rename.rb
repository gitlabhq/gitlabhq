# frozen_string_literal: true

class CleanupMlCandidatesIidRename < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :ml_candidates, :iid, :eid
  end

  def down
    undo_cleanup_concurrent_column_rename :ml_candidates, :iid, :eid
  end
end
