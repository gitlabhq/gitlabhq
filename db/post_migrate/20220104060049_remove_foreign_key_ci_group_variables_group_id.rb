# frozen_string_literal: true

class RemoveForeignKeyCiGroupVariablesGroupId < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_33ae4d58d8'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_group_variables, :namespaces, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key :ci_group_variables, :namespaces, column: :group_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
