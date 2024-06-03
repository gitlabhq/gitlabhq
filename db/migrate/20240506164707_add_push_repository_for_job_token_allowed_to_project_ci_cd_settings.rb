# frozen_string_literal: true

class AddPushRepositoryForJobTokenAllowedToProjectCiCdSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :project_ci_cd_settings, :push_repository_for_job_token_allowed,
      :boolean, default: false, null: false
  end
end
