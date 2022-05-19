# frozen_string_literal: true

class UpdateBatchedBackgroundMigrationArguments < Gitlab::Database::Migration[1.0]
  def up
    execute(<<~SQL)
      UPDATE batched_background_migrations
      SET job_arguments = '[]'
      WHERE job_arguments = '"[]"';
    SQL
  end

  def down
    execute(<<~SQL)
      UPDATE batched_background_migrations
      SET job_arguments = '"[]"'
      WHERE job_arguments = '[]';
    SQL
  end
end
