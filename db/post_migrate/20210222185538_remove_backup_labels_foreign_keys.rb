# frozen_string_literal: true

class RemoveBackupLabelsForeignKeys < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:backup_labels, :projects)
      remove_foreign_key_if_exists(:backup_labels, :namespaces)
    end
  end

  def down
    add_concurrent_foreign_key(:backup_labels, :projects, column: :project_id, on_delete: :cascade)
    add_concurrent_foreign_key(:backup_labels, :namespaces, column: :group_id, on_delete: :cascade)
  end
end
