# frozen_string_literal: true

class RemoveCiMinutesAdditionalPacksNamespaceIdForeignKeyConstraint < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'fk_rails_e0e0c4e4b1'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:ci_minutes_additional_packs, :namespaces, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_foreign_key :ci_minutes_additional_packs, :namespaces, column: :namespace_id, on_delete: :cascade, name: CONSTRAINT_NAME
  end
end
