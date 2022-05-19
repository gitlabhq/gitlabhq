# frozen_string_literal: true

class FinalizeTraversalIdsBackgroundMigrations < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    finalize_background_migration('BackfillNamespaceTraversalIdsRoots')
    finalize_background_migration('BackfillNamespaceTraversalIdsChildren')
  end

  def down
    # no-op
  end
end
