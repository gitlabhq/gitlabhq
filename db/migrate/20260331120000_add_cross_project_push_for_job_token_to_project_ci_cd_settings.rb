# frozen_string_literal: true

class AddCrossProjectPushForJobTokenToProjectCiCdSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :project_ci_cd_settings, :cross_project_push_for_job_token_allowed, :boolean, default: false, null: false
  end
end
