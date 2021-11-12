# frozen_string_literal: true

class AddHasShimoToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :has_shimo, :boolean, default: false, null: false
  end
end
