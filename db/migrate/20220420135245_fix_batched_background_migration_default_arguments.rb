# frozen_string_literal: true

class FixBatchedBackgroundMigrationDefaultArguments < Gitlab::Database::Migration[1.0]
  def change
    change_column_default :batched_background_migrations, :job_arguments, from: '[]', to: []
  end
end
