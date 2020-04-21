# frozen_string_literal: true

class AddPrivateCommitEmailHostnameToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column(:application_settings, :commit_email_hostname, :string, null: true)
  end
  # rubocop:enable Migration/PreventStrings
end
