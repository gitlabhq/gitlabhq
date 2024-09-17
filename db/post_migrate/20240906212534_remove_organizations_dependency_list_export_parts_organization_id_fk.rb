# frozen_string_literal: true

class RemoveOrganizationsDependencyListExportPartsOrganizationIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_ef73d6ad62"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:dependency_list_export_parts, :organizations,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:dependency_list_export_parts, :organizations,
      name: FOREIGN_KEY_NAME, column: :organization_id,
      target_column: :id, on_delete: :cascade)
  end
end
