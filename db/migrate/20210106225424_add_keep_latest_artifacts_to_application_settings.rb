# frozen_string_literal: true

class AddKeepLatestArtifactsToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    # This is named keep_latest_artifact for consistency with the project level setting but
    # turning it on keeps all (multiple) artifacts on the latest pipeline per ref
    add_column :application_settings, :keep_latest_artifact, :boolean, default: true, null: false
  end
end
