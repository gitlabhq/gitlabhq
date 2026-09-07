# frozen_string_literal: true

class AddCodeDropdownCustomClientsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    add_column :application_settings, :code_dropdown_custom_clients, :jsonb, null: false, default: []
  end

  def down
    remove_column :application_settings, :code_dropdown_custom_clients, if_exists: true
  end
end
