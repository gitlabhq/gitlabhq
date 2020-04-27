# frozen_string_literal: true

class AddLockedToCiJobArtifact < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :ci_job_artifacts, :locked, :boolean
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_job_artifacts, :locked
    end
  end
end
