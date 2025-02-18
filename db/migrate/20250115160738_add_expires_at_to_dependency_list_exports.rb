# frozen_string_literal: true

class AddExpiresAtToDependencyListExports < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :dependency_list_exports, :expires_at, :timestamptz, if_not_exists: true
  end
end
