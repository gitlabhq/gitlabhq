# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLetsEncryptPrivateKeyToApplicationSettings < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :application_settings, :encrypted_lets_encrypt_private_key, :text
    add_column :application_settings, :encrypted_lets_encrypt_private_key_iv, :text
  end
end
