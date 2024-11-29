# frozen_string_literal: true

class AddDeletePipelinesInSecondsToProjectCiCdSettings < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :project_ci_cd_settings, :delete_pipelines_in_seconds, :integer
  end
end
