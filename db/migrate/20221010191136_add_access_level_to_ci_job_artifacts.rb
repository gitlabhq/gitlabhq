# frozen_string_literal: true

class AddAccessLevelToCiJobArtifacts < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :ci_job_artifacts, :accessibility, :integer, default: 0, limit: 2, null: false
  end
end
