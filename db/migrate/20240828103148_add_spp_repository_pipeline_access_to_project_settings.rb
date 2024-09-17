# frozen_string_literal: true

class AddSppRepositoryPipelineAccessToProjectSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.4'

  def change
    add_column :project_settings, :spp_repository_pipeline_access, :boolean
  end
end
