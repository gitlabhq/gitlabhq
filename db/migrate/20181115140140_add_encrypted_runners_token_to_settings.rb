# frozen_string_literal: true

class AddEncryptedRunnersTokenToSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :runners_registration_token_encrypted, :string
  end
end
