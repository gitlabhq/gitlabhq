# frozen_string_literal: true

class AddForeignKeyToPackagesComposerPackagesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :packages_composer_packages

  def up
    add_concurrent_foreign_key TABLE_NAME, :projects, column: :project_id, on_delete: :cascade,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, column: :project_id, reverse_lock_order: true
    end
  end
end
