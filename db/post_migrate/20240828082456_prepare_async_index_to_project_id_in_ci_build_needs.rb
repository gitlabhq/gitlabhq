# frozen_string_literal: true

class PrepareAsyncIndexToProjectIdInCiBuildNeeds < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  TABLE_NAME = :ci_build_needs
  INDEX_NAME = :index_ci_build_needs_on_project_id

  def up
    prepare_async_index TABLE_NAME, :project_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, :project_id, name: INDEX_NAME
  end
end
