# frozen_string_literal: true

class AddIndexToPackagesMavenMetadataPath < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_maven_metadata_on_path'

  def up
    add_concurrent_index :packages_maven_metadata, :path, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :packages_maven_metadata, :path, name: INDEX_NAME
  end
end
