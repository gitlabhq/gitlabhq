# frozen_string_literal: true

class AddUniqueIndexForMlModelPackages < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'uniq_idx_packages_packages_on_project_id_name_version_ml_model'
  PACKAGE_TYPE_ML_MODEL = 14

  disable_ddl_transaction!

  def up
    add_concurrent_index :packages_packages, [:project_id, :name, :version],
      unique: true,
      where: "package_type = #{PACKAGE_TYPE_ML_MODEL}",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:packages_packages, INDEX_NAME)
  end
end
