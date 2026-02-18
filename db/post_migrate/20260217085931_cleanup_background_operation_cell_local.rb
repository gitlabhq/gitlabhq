# frozen_string_literal: true

class CleanupBackgroundOperationCellLocal < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_shared_cell_local

  milestone '18.10'

  def up
    return unless Gitlab.com_except_jh?

    connection.execute(<<~SQL)
      DELETE FROM background_operation_workers_cell_local;
      DELETE FROM background_operation_jobs_cell_local;
    SQL
  end

  def down; end
end
