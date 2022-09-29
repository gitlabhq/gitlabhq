# frozen_string_literal: true

class AddCanCreateGroupToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column(:application_settings, :can_create_group, :boolean, default: true, null: false)
  end
end
