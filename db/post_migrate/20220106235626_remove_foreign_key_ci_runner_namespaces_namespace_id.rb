# frozen_string_literal: true

class RemoveForeignKeyCiRunnerNamespacesNamespaceId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_rails_f9d9ed3308'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_runner_namespaces, :namespaces, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key :ci_runner_namespaces, :namespaces, column: :namespace_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
