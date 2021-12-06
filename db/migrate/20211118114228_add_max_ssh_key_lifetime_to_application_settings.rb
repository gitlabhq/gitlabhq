# frozen_string_literal: true

class AddMaxSshKeyLifetimeToApplicationSettings < Gitlab::Database::Migration[1.0]
  def change
    add_column :application_settings, :max_ssh_key_lifetime, :integer
  end
end
