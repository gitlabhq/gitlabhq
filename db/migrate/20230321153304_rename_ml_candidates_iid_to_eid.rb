# frozen_string_literal: true

class RenameMlCandidatesIidToEid < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :ml_candidates, :iid, :eid
  end

  def down
    undo_rename_column_concurrently :ml_candidates, :iid, :eid
  end
end
