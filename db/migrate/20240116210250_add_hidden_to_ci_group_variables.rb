# frozen_string_literal: true

class AddHiddenToCiGroupVariables < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :ci_group_variables, :hidden, :boolean, null: false, default: false
  end
end
