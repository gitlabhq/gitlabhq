# frozen_string_literal: true

class AddConfigColumnToCiRunnerMachines < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :ci_runner_machines, :config, :jsonb, default: {}, null: false
  end
end
