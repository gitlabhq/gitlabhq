# frozen_string_literal: true

class RemoveRunnersRegistrationTokenFromApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    remove_column :application_settings, :runners_registration_token
  end

  def down
    add_column :application_settings, :runners_registration_token, :string
  end
end
