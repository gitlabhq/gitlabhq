# frozen_string_literal: true

class CreateSecurityScan < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :security_scans, id: :bigserial do |t|
      t.timestamps_with_timezone null: false

      t.references :build,
                   null: false,
                   index: false,
                   foreign_key: { to_table: :ci_builds, on_delete: :cascade },
                   type: :bigint

      t.integer :scan_type,
                null: false,
                index: { name: "idx_security_scans_on_scan_type" },
                limit: 2

      t.index [:build_id, :scan_type], name: "idx_security_scans_on_build_and_scan_type", unique: true
    end
  end
end
