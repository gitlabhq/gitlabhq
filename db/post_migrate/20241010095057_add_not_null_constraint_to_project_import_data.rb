# frozen_string_literal: true

class AddNotNullConstraintToProjectImportData < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    change_column_null :project_import_data, :project_id, false
  end

  def down
    change_column_null :project_import_data, :project_id, true
  end
end
