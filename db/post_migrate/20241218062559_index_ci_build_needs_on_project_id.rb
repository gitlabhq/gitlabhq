# frozen_string_literal: true

class IndexCiBuildNeedsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  TABLE_NAME = :ci_build_needs
  INDEX_NAME = :index_ci_build_needs_on_project_id

  def up
    add_concurrent_index TABLE_NAME, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
