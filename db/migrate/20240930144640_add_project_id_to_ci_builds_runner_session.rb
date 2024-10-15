# frozen_string_literal: true

class AddProjectIdToCiBuildsRunnerSession < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_builds_runner_session, :project_id, :bigint
  end
end
