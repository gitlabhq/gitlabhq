# frozen_string_literal: true

class AddInvisibleCaptchaEnabledToSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :invisible_captcha_enabled, :boolean, null: false, default: false
  end
end
