# frozen_string_literal: true

class AddDefaultValueForFileStoreToPipelineArtifact < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  PIPELINE_ARTIFACT_LOCAL_FILE_STORE = 1

  def up
    with_lock_retries do
      change_column_default :ci_pipeline_artifacts, :file_store, PIPELINE_ARTIFACT_LOCAL_FILE_STORE
    end
  end

  def down
    with_lock_retries do
      change_column_default :ci_pipeline_artifacts, :file_store, nil
    end
  end
end
