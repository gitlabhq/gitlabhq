# frozen_string_literal: true

class AddHiddenToCiInstanceVariables < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :ci_instance_variables, :hidden, :boolean, default: false, null: false
  end
end
