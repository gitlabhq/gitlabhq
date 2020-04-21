# frozen_string_literal: true

class AddVerificationColumnsToPackages < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :packages_package_files, :verification_retry_at, :datetime_with_timezone
    add_column :packages_package_files, :verified_at, :datetime_with_timezone
    add_column :packages_package_files, :verification_checksum, :string, limit: 255
    add_column :packages_package_files, :verification_failure, :string, limit: 255
    add_column :packages_package_files, :verification_retry_count, :integer
  end
  # rubocop:enable Migration/PreventStrings
end
