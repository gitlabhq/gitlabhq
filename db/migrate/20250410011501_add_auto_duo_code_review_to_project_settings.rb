# frozen_string_literal: true

class AddAutoDuoCodeReviewToProjectSettings < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    add_column :project_settings, :auto_duo_code_review_enabled, :boolean, default: false, null: false
  end

  def down
    remove_column :project_settings, :auto_duo_code_review_enabled
  end
end
