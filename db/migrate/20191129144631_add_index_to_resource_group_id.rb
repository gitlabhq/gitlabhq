# frozen_string_literal: true

class AddIndexToResourceGroupId < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_for_resource_group'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, %i[resource_group_id id], where: 'resource_group_id IS NOT NULL', name: INDEX_NAME
    add_concurrent_foreign_key :ci_builds, :ci_resource_groups, column: :resource_group_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :ci_builds, column: :resource_group_id
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end
end
