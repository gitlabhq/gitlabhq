# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLetsEncryptNotificationEmailToApplicationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :application_settings, :lets_encrypt_notification_email, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
