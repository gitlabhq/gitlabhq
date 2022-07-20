# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddEncryptedErrorTrackingAccessToken < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_column :application_settings, :error_tracking_access_token_encrypted, :text, if_not_exists: true
    add_text_limit :application_settings, :error_tracking_access_token_encrypted, 255
  end

  def down
    remove_column :application_settings, :error_tracking_access_token_encrypted, if_exists: true
  end
end
