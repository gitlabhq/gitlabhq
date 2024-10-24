# frozen_string_literal: true

class AddColumnsToPackagesConanFileMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :packages_conan_file_metadata, :recipe_revision_id, :bigint
    add_column :packages_conan_file_metadata, :package_revision_id, :bigint
    add_column :packages_conan_file_metadata, :package_reference_id, :bigint
  end
end
