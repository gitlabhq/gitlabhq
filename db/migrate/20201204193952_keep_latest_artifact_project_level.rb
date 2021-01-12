# frozen_string_literal: true

class KeepLatestArtifactProjectLevel < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_ci_cd_settings, :keep_latest_artifact, :boolean, default: true, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_ci_cd_settings, :keep_latest_artifact
    end
  end
end
