# frozen_string_literal: true

class AddProjectNamespaceForeignKeyToProject < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TARGET_COLUMN = :project_namespace_id

  def up
    add_concurrent_foreign_key :projects, :namespaces, column: TARGET_COLUMN, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:projects, column: TARGET_COLUMN)
    end
  end
end
