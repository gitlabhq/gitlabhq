class AddPasswordAuthenticationEnabledForGitToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :password_authentication_enabled_for_git, :boolean, default: true, null: false
  end
end
