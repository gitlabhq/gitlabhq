# frozen_string_literal: true

class RemoveForeignKeyCiPendingBuildsNamespaceId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_fdc0137e4a'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_pending_builds, :namespaces, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key :ci_pending_builds, :namespaces, column: :namespace_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
