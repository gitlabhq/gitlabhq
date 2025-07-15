# frozen_string_literal: true

class ChangeProjectSettingsSppRepositoryPipelineAccessDefault < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    change_column_default('project_settings', 'spp_repository_pipeline_access', from: nil, to: true)
  end
end
