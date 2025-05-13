# frozen_string_literal: true

class AddIndexImportPlaceholderUserDetailsPrimary < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_import_placeholder_user_details_on_eligible_for_deletion'

  def up
    add_concurrent_index :import_placeholder_user_details,
      [:deletion_attempts, :last_deletion_attempt_at, :id],
      name: INDEX_NAME,
      where: "(namespace_id IS NULL)"
  end

  def down
    remove_concurrent_index_by_name :import_placeholder_user_details, INDEX_NAME
  end
end
