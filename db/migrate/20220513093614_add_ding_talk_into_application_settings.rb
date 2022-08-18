# frozen_string_literal: true

class AddDingTalkIntoApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :dingtalk_integration_enabled, :boolean,
      null: false, default: false, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_dingtalk_corpid, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_dingtalk_corpid_iv, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_dingtalk_app_key, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_dingtalk_app_key_iv, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_dingtalk_app_secret, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_dingtalk_app_secret_iv, :binary, comment: 'JiHu-specific column'
  end
end
