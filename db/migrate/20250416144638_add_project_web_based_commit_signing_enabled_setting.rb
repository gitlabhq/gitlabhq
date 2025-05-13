# frozen_string_literal: true

class AddProjectWebBasedCommitSigningEnabledSetting < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def change
    add_column :project_settings, :web_based_commit_signing_enabled, :boolean, default: false, null: false
  end
end
