# frozen_string_literal: true

class UpdateCiMaxArtifactSizeLsifOfPlanLimitsFrom100To200 < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.8'

  def up
    execute('UPDATE plan_limits SET ci_max_artifact_size_lsif = 200 WHERE ci_max_artifact_size_lsif = 100')
  end

  def down
    execute('UPDATE plan_limits SET ci_max_artifact_size_lsif = 100 WHERE ci_max_artifact_size_lsif = 200')
  end
end
