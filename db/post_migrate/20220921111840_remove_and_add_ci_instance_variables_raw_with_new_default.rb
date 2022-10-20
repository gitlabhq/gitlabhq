# frozen_string_literal: true

class RemoveAndAddCiInstanceVariablesRawWithNewDefault < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    remove_column :ci_instance_variables, :raw, :boolean, null: false, default: true
    add_column :ci_instance_variables, :raw, :boolean, null: false, default: false
  end
end
