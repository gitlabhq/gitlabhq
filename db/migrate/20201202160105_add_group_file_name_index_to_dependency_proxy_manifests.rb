# frozen_string_literal: true

class AddGroupFileNameIndexToDependencyProxyManifests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  NEW_INDEX = 'index_dependency_proxy_manifests_on_group_id_and_file_name'
  OLD_INDEX = 'index_dependency_proxy_manifests_on_group_id_and_digest'

  def up
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :file_name], name: NEW_INDEX, unique: true
    remove_concurrent_index_by_name :dependency_proxy_manifests, OLD_INDEX
  end

  def down
    add_concurrent_index :dependency_proxy_manifests, [:group_id, :digest], name: OLD_INDEX
    remove_concurrent_index_by_name :dependency_proxy_manifests, NEW_INDEX
  end
end
