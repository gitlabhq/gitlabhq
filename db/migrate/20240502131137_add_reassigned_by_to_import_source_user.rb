# frozen_string_literal: true

class AddReassignedByToImportSourceUser < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.0'

  TABLE_NAME = :import_source_users
  COLUMN_NAME = :reassigned_by_user_id

  def up
    add_column TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true

    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: "index_#{TABLE_NAME}_on_#{COLUMN_NAME}"
    add_concurrent_foreign_key TABLE_NAME, :users, column: COLUMN_NAME, on_delete: :nullify
  end

  def down
    remove_column TABLE_NAME, COLUMN_NAME
  end
end
