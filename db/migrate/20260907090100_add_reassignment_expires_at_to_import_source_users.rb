# frozen_string_literal: true

class AddReassignmentExpiresAtToImportSourceUsers < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :import_source_users
  COLUMN_NAME = :reassignment_expires_at
  INDEX_NAME = :index_import_source_users_on_reassignment_expires_at

  def up
    add_column TABLE_NAME, COLUMN_NAME, :datetime_with_timezone

    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME

    remove_column TABLE_NAME, COLUMN_NAME
  end
end
