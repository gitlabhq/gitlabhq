# frozen_string_literal: true

class AddSpamcheckApiKeyToApplicationSetting < ActiveRecord::Migration[6.0]
  def up
    add_column :application_settings, :encrypted_spam_check_api_key, :binary
    add_column :application_settings, :encrypted_spam_check_api_key_iv, :binary
  end

  def down
    remove_column :application_settings, :encrypted_spam_check_api_key
    remove_column :application_settings, :encrypted_spam_check_api_key_iv
  end
end
