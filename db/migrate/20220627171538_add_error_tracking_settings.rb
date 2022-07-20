# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddErrorTrackingSettings < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_column :application_settings, :error_tracking_enabled, :boolean,
      default: false, null: false, if_not_exists: true

    add_column :application_settings, :error_tracking_api_url, :text, if_not_exists: true
    add_text_limit :application_settings, :error_tracking_api_url, 255
  end

  def down
    remove_column :application_settings, :error_tracking_enabled, if_exists: true
    remove_column :application_settings, :error_tracking_api_url, if_exists: true
  end
end
