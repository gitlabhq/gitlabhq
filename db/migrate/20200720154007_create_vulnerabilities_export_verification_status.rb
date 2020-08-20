# frozen_string_literal: true

class CreateVulnerabilitiesExportVerificationStatus < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:vulnerability_export_verification_status)
      with_lock_retries do
        create_table :vulnerability_export_verification_status, id: false do |t|
          t.references :vulnerability_export,
            primary_key: true,
            null: false,
            foreign_key: { on_delete: :cascade },
            index:
              { name: 'index_vulnerability_export_verification_status_on_export_id' }
          t.datetime_with_timezone :verification_retry_at
          t.datetime_with_timezone :verified_at
          t.integer :verification_retry_count, limit: 2
          t.binary :verification_checksum, using: 'verification_checksum::bytea'
          t.text :verification_failure

          t.index :verification_failure, where: "(verification_failure IS NOT NULL)", name: "vulnerability_exports_verification_failure_partial"
          t.index :verification_checksum, where: "(verification_checksum IS NOT NULL)", name: "vulnerability_exports_verification_checksum_partial"
        end
      end
    end

    add_text_limit :vulnerability_export_verification_status, :verification_failure, 255
  end

  def down
    return unless table_exists?(:vulnerability_export_verification_status)

    with_lock_retries do
      drop_table :vulnerability_export_verification_status
    end
  end
end
