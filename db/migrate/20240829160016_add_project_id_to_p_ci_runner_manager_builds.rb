# frozen_string_literal: true

class AddProjectIdToPCiRunnerManagerBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column(:p_ci_runner_machine_builds, :project_id, :bigint)
  end
end
