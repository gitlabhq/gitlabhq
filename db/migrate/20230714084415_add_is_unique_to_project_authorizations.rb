# frozen_string_literal: true

class AddIsUniqueToProjectAuthorizations < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :project_authorizations, :is_unique, :boolean, null: true
  end
end
