# frozen_string_literal: true

class AddAuthSigningTypeToKeys < Gitlab::Database::Migration[2.0]
  def change
    add_column :keys, :usage_type, :integer, limit: 2, null: false, default: 0
  end
end
