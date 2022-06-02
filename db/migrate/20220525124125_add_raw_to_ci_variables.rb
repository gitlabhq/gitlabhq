# frozen_string_literal: true

class AddRawToCiVariables < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_variables, :raw, :boolean, null: false, default: true
  end
end
