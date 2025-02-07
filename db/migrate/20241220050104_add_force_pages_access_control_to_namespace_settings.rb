# frozen_string_literal: true

class AddForcePagesAccessControlToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :namespace_settings, :force_pages_access_control, :boolean, default: false, null: false
  end
end
