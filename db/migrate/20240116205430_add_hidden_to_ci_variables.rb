# frozen_string_literal: true

class AddHiddenToCiVariables < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :ci_variables, :hidden, :boolean, null: false, default: false
  end
end
