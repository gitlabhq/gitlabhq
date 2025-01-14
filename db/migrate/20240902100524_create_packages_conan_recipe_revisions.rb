# frozen_string_literal: true

class CreatePackagesConanRecipeRevisions < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  INDEX_PACKAGE_ID_REVISION = 'idx_on_packages_conan_recipe_revisions_package_id_revision'

  def up
    create_table :packages_conan_recipe_revisions do |t|
      t.bigint :package_id, null: false
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.binary :revision, null: false, limit: 20 # It is either an MD5 hash (16 bytes) or a SHA-1 hash (20 bytes)

      t.index :project_id
      # Composite index to ensure we don't have duplicate revisions per a package.
      t.index [:package_id, :revision], unique: true, name: INDEX_PACKAGE_ID_REVISION
    end
  end

  def down
    drop_table :packages_conan_recipe_revisions
  end
end
