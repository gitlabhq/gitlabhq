# frozen_string_literal: true

class AddPasswordExpirationMigration < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :password_expiration_enabled, :boolean, default: false, null: false,
                                                                              comment: 'JiHu-specific column'
    add_column :application_settings, :password_expires_in_days, :integer, default: 90, null: false,
                                                                           comment: 'JiHu-specific column'
    add_column :application_settings, :password_expires_notice_before_days, :integer, default: 7, null: false,
                                                                                      comment: 'JiHu-specific column'
  end
end
