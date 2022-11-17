# frozen_string_literal: true

class ChangeEmailConfirmationSettingDefault < Gitlab::Database::Migration[2.0]
  def change
    change_column_default(:application_settings, :email_confirmation_setting, from: 2, to: 0)
  end
end
