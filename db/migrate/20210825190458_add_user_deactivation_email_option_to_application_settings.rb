# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddUserDeactivationEmailOptionToApplicationSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :application_settings, :user_deactivation_emails_enabled, :boolean, default: true, null: false
  end
end
