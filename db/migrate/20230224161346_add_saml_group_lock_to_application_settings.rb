# frozen_string_literal: true

class AddSamlGroupLockToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :lock_memberships_to_saml, :boolean, default: false, null: false
  end
end
