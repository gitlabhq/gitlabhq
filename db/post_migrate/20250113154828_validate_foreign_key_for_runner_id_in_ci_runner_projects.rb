# frozen_string_literal: true

class ValidateForeignKeyForRunnerIdInCiRunnerProjects < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    validate_foreign_key(:ci_runner_projects, :runner_id)
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
