# frozen_string_literal: true

class AddPipelineCreateLimitPerProjectUserShaToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :pipeline_limit_per_project_user_sha, :integer, default: 0, null: false
  end
end
