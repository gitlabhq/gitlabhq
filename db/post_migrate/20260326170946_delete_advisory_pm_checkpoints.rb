# frozen_string_literal: true

class DeleteAdvisoryPmCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_pm

  def up
    execute <<~SQL
      DELETE FROM pm_checkpoints
      WHERE data_type = 1
    SQL
  end

  def down
    # no-op - deleted rows cannot be restored, sync will recreate them
  end
end
