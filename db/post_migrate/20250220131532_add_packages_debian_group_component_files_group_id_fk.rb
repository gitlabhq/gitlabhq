# frozen_string_literal: true

class AddPackagesDebianGroupComponentFilesGroupIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :packages_debian_group_component_files, :namespaces, column: :group_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :packages_debian_group_component_files, column: :group_id
    end
  end
end
