# frozen_string_literal: true

class AddDefaultValueForFileStoreToCiJobArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :ci_job_artifacts, :file_store, 1
    end
  end

  def down
    with_lock_retries do
      change_column_default :ci_job_artifacts, :file_store, nil
    end
  end
end
