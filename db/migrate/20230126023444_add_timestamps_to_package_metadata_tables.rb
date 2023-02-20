# frozen_string_literal: true

class AddTimestampsToPackageMetadataTables < Gitlab::Database::Migration[2.1]
  def up
    add_timestamps_with_timezone(:pm_packages, null: false, default: -> { 'NOW()' })
    add_timestamps_with_timezone(:pm_package_versions, null: false, default: -> { 'NOW()' })
    add_timestamps_with_timezone(:pm_licenses, null: false, default: -> { 'NOW()' })
    add_timestamps_with_timezone(:pm_package_version_licenses, null: false, default: -> { 'NOW()' })
  end

  def down
    remove_timestamps(:pm_packages)
    remove_timestamps(:pm_package_versions)
    remove_timestamps(:pm_licenses)
    remove_timestamps(:pm_package_version_licenses)
  end
end
