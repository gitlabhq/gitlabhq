# frozen_string_literal: true

class AddMavenPackageRequestsForwardingToApplicationSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column(:application_settings, :maven_package_requests_forwarding, :boolean, default: true, null: false)
  end

  def down
    remove_column(:application_settings, :maven_package_requests_forwarding)
  end
end
