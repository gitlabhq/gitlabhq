# frozen_string_literal: true

class AddUniqIndexPackageReference < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  INDEX_NAME = 'uniq_index_pkg_refs_on_ref_and_pkg_id_when_rev_is_null'

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_conan_package_references,
      [:package_id, :reference],
      unique: true,
      name: INDEX_NAME,
      where: 'recipe_revision_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :packages_conan_package_references, INDEX_NAME
  end
end
