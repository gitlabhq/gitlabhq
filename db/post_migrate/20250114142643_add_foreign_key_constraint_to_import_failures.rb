# frozen_string_literal: true

class AddForeignKeyConstraintToImportFailures < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :import_failures, :projects, column: :project_id, on_delete: :cascade, validate: false
  end

  def down
    remove_foreign_key_if_exists :import_failures, column: :project_id
  end
end
