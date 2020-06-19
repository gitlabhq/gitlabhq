# frozen_string_literal: true

class AddIndexOnWikiSizeAndProjectIdToProjectStatistics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_statistics, [:wiki_size, :project_id]
  end

  def down
    remove_concurrent_index :project_statistics, [:wiki_size, :project_id]
  end
end
