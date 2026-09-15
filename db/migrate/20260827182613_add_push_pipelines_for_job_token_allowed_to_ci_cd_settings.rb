# frozen_string_literal: true

class AddPushPipelinesForJobTokenAllowedToCiCdSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column(
      :project_ci_cd_settings,
      :push_pipelines_for_job_token_allowed,
      :boolean,
      default: false,
      null: false
    )
  end
end
