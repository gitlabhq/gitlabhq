# frozen_string_literal: true

class AddIndexOnProjectIdAndBuildsAccessLevelToProjectFeatures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_project_features_on_project_id_bal_20'

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_features, :project_id, where: 'builds_access_level = 20', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_features, INDEX_NAME
  end
end
