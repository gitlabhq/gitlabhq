# frozen_string_literal: true

class AddPhoneVerificationCodeEnabledToApplicationSettings < Gitlab::Database::Migration[2.0]
  def up
    add_column :application_settings,
               :phone_verification_code_enabled,
               :boolean,
               null: false,
               default: false,
               comment: 'JiHu-specific column'
  end

  def down
    remove_column :application_settings, :phone_verification_code_enabled
  end
end
