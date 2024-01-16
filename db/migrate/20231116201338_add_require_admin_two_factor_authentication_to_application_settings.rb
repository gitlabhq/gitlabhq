# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRequireAdminTwoFactorAuthenticationToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def change
    add_column :application_settings, :require_admin_two_factor_authentication, :boolean, default: false, null: false
  end
end
