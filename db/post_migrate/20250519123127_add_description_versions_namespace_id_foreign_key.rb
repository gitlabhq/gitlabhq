# frozen_string_literal: true

class AddDescriptionVersionsNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :description_versions, :namespaces, column: :namespace_id, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key :description_versions, column: :namespace_id
    end
  end
end
