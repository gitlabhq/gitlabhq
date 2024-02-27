# frozen_string_literal: true

class AddVisibilityLevelToOrganizations < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  enable_lock_retries!

  def change
    add_column :organizations, :visibility_level, :smallint, default: 0, null: false
  end
end
