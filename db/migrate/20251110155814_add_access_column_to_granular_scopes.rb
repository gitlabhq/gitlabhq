# frozen_string_literal: true

class AddAccessColumnToGranularScopes < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column :granular_scopes, :access, :integer, limit: 2, default: 0, null: false
  end
end
