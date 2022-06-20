# frozen_string_literal: true

class AddRawToCiJobVariables < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_job_variables, :raw, :boolean, null: false, default: true
  end
end
