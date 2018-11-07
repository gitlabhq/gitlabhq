# frozen_string_literal: true

class AddPrivateCommitEmailHostnameToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:application_settings, :commit_email_hostname, :string, null: true)
  end
end
