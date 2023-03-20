# frozen_string_literal: true

class RemoveApplicationSettingsSendUserConfirmationEmailColumn < Gitlab::Database::Migration[2.1]
  def change
    remove_column :application_settings, :send_user_confirmation_email, :boolean, default: false
  end
end
