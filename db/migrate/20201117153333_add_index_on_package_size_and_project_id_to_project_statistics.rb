# frozen_string_literal: true

class AddIndexOnPackageSizeAndProjectIdToProjectStatistics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_project_statistics_on_packages_size_and_project_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_statistics, [:packages_size, :project_id],
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_statistics, INDEX_NAME
  end
end
