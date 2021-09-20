# frozen_string_literal: true

class AddPackageFileIdChannelIdxToPackagesHelmFileMetadata < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_helm_file_metadata_on_pf_id_and_channel'

  def up
    add_concurrent_index :packages_helm_file_metadata, [:package_file_id, :channel], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :packages_helm_file_metadata, [:package_file_id, :channel], name: INDEX_NAME
  end
end
