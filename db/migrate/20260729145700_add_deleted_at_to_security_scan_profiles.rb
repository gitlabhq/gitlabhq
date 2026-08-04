# frozen_string_literal: true

class AddDeletedAtToSecurityScanProfiles < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :security_scan_profiles, :deleted_at, :datetime_with_timezone
  end
end
