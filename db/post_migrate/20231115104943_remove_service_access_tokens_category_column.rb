# frozen_string_literal: true

class RemoveServiceAccessTokensCategoryColumn < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    remove_column :service_access_tokens, :category, :integer, limit: 2, default: 0, null: false
  end
end
