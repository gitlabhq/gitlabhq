# frozen_string_literal: true

class CreatePackagesConanPackageReferences < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  UNIQ_IND_PACKAGE_REVISION_REF = 'uniq_idx_on_packages_conan_package_references_package_reference'
  CONSTRAINT_NAME = 'chk_conan_references_info_length'

  def up
    create_table :packages_conan_package_references do |t|
      t.bigint :package_id, null: false
      t.bigint :project_id, null: false
      t.bigint :recipe_revision_id
      t.timestamps_with_timezone null: false
      t.binary :reference, null: false, limit: 20 # A SHA-1 hash (20 bytes)
      t.jsonb :info, default: {}, null: false

      t.index :project_id
      t.index :recipe_revision_id
      t.index [:package_id, :recipe_revision_id, :reference], unique: true, name: UNIQ_IND_PACKAGE_REVISION_REF

      t.check_constraint "char_length(info::text) <= 20000", name: CONSTRAINT_NAME
    end
  end

  def down
    drop_table :packages_conan_package_references
  end
end
