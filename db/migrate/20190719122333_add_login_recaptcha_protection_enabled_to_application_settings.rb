# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLoginRecaptchaProtectionEnabledToApplicationSettings < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :application_settings, :login_recaptcha_protection_enabled, :boolean, default: false, null: false
  end
end
