# frozen_string_literal: true

class CleanupRunnerProjectsWithNullProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '17.1'

  class CiRunnerProject < MigrationRecord
    self.table_name = 'ci_runner_projects'
  end

  def up
    CiRunnerProject.where(project_id: nil).delete_all
  end

  def down
    # no-op : can't recover deleted records
  end
end
