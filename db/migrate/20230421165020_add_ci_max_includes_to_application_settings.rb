# frozen_string_literal: true

class AddCiMaxIncludesToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :ci_max_includes, :integer, default: 150, null: false
  end
end
