# frozen_string_literal: true

class AddForeignKeyToProjectIdOnPipelineArtifact < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :ci_pipeline_artifacts, :projects, column: :project_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :ci_pipeline_artifacts, column: :project_id
    end
  end
end
