# frozen_string_literal: true

class AddUserToBulkImportsExport < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  TABLE_NAME = :bulk_import_exports
  COLUMN_NAME = :user_id

  def up
    add_column TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true
  end

  def down
    remove_column TABLE_NAME, COLUMN_NAME
  end
end
