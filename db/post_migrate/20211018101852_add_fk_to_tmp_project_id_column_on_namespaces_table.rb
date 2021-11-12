# frozen_string_literal: true

class AddFkToTmpProjectIdColumnOnNamespacesTable < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :namespaces, :projects, column: :tmp_project_id
  end

  def down
    remove_foreign_key :namespaces, column: :tmp_project_id
  end
end
