# frozen_string_literal: true

class AddNetworkSettingsToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :ai_settings, :include_recommended_allowed, :boolean, default: false, null: false
    add_column :ai_settings, :allow_all_unix_sockets, :boolean, default: false, null: false
    add_column :ai_settings, :enforce_on_local_clients, :boolean, default: false, null: false
    add_column :ai_settings, :allow_project_extension, :boolean, default: true, null: false
    add_column :ai_settings, :allowed_domains, :text, default: [], array: true, null: false
    add_column :ai_settings, :denied_domains, :text, default: [], array: true, null: false
  end
end
