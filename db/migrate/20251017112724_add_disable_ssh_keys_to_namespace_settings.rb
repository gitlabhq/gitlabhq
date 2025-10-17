# frozen_string_literal: true

class AddDisableSshKeysToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :namespace_settings, :disable_ssh_keys, :boolean, default: false, null: false
  end

  def down
    remove_column :namespace_settings, :disable_ssh_keys
  end
end
