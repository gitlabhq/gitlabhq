# frozen_string_literal: true

class RedoRemoveAndAddCiJobVariablesRawWithNewDefault < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  # We are removing and adding the same column with the same parameters to refresh the table
  # because we have some wrong `ci_job_variables.raw` data (`TRUE`) in the database.
  def change
    remove_column :ci_job_variables, :raw, :boolean, null: false, default: false
    add_column :ci_job_variables, :raw, :boolean, null: false, default: false
  end
end
