# frozen_string_literal: true

class AddPackageIdAsForeignKeyInPackagesConanPackageReferences < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :packages_conan_package_references, :packages_packages, column: :package_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :packages_conan_package_references, column: :package_id
    end
  end
end
