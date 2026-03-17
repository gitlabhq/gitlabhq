# frozen_string_literal: true

class AddPackagesPackageFileStatesProjectIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :packages_package_file_states, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :packages_package_file_states, column: :project_id
    end
  end
end
