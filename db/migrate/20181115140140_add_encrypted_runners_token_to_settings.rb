# frozen_string_literal: true

class AddEncryptedRunnersTokenToSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :application_settings, :runners_registration_token_encrypted, :string
  end
  # rubocop:enable Migration/PreventStrings
end
