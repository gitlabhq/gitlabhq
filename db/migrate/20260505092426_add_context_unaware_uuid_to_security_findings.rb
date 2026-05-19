# frozen_string_literal: true

class AddContextUnawareUuidToSecurityFindings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- This is already a partitioned table, max partition size is 100GB
    # This field should not be nil going forwards, but will either need backfilled with a BBM or just by waiting until
    # a suitable time in the future where we can guarantee all data without this field will have been expired.
    add_column :security_findings, :context_unaware_uuid, :uuid, null: true, if_not_exists: true
    # rubocop:enable Migration/PreventAddingColumns
  end
end
