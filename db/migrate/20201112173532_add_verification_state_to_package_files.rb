# frozen_string_literal: true

class AddVerificationStateToPackageFiles < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :packages_package_files, :verification_state, :integer, default: 0, limit: 2, null: false
    add_column :packages_package_files, :verification_started_at, :datetime_with_timezone
  end
end
