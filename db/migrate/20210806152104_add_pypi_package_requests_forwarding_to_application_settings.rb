# frozen_string_literal: true

class AddPypiPackageRequestsForwardingToApplicationSettings < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      add_column(:application_settings, :pypi_package_requests_forwarding, :boolean, default: true, null: false)
    end
  end

  def down
    with_lock_retries do
      remove_column(:application_settings, :pypi_package_requests_forwarding)
    end
  end
end
