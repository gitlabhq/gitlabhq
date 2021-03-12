# frozen_string_literal: true

class AddDeployedDeploymentIdIndexToProjectPagesMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_on_pages_metadata_not_migrated'

  def up
    add_concurrent_index :project_pages_metadata, :project_id, where: "deployed = TRUE AND pages_deployment_id is NULL", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_pages_metadata, INDEX_NAME
  end
end
