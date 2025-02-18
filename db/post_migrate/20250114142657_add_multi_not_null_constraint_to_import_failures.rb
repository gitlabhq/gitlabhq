# frozen_string_literal: true

class AddMultiNotNullConstraintToImportFailures < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    add_multi_column_not_null_constraint(:import_failures, :group_id, :project_id, :organization_id)
  end

  def down
    remove_multi_column_not_null_constraint(:import_failures, :group_id, :project_id, :organization_id)
  end
end
