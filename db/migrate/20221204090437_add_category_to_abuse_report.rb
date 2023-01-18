# frozen_string_literal: true

class AddCategoryToAbuseReport < Gitlab::Database::Migration[2.1]
  def change
    add_column :abuse_reports, :category, :integer, limit: 2, default: 1, null: false
  end
end
