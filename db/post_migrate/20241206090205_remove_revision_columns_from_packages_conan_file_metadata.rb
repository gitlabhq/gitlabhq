# frozen_string_literal: true

class RemoveRevisionColumnsFromPackagesConanFileMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    remove_column :packages_conan_file_metadata, :recipe_revision, :string
    remove_column :packages_conan_file_metadata, :package_revision, :string
  end

  def down
    add_column :packages_conan_file_metadata, :recipe_revision, :string, limit: 255, default: '0', null: false
    add_column :packages_conan_file_metadata, :package_revision, :string, limit: 255
  end
end
