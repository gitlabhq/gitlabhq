# frozen_string_literal: true

class AddAllowCompositeIdentitiesToRunPipelinesToProjectCiCdSettings < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :project_ci_cd_settings, :allow_composite_identities_to_run_pipelines, :boolean,
      default: false, null: false
  end
end
