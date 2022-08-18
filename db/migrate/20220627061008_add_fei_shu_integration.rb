# frozen_string_literal: true

class AddFeiShuIntegration < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :feishu_integration_enabled, :boolean,
      null: false, default: false, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_feishu_app_key, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_feishu_app_key_iv, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_feishu_app_secret, :binary, comment: 'JiHu-specific column'
    add_column :application_settings, :encrypted_feishu_app_secret_iv, :binary, comment: 'JiHu-specific column'
  end
end
