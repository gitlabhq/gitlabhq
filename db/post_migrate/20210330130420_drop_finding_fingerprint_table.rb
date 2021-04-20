# frozen_string_literal: true

class DropFindingFingerprintTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  FINGERPRINT_IDX = :idx_vuln_fingerprints_on_occurrences_id_and_fingerprint_sha256
  UNIQ_IDX = :idx_vuln_fingerprints_uniqueness_fingerprint_sha256

  def up
    with_lock_retries do
      drop_table :vulnerability_finding_fingerprints
    end
  end

  def down
    with_lock_retries do
      create_table :vulnerability_finding_fingerprints do |t|
        t.references :finding,
          index: true,
          null: false,
          foreign_key: { to_table: :vulnerability_occurrences, column: :finding_id, on_delete: :cascade }

        t.timestamps_with_timezone null: false

        t.integer :algorithm_type, null: false, limit: 2
        t.binary :fingerprint_sha256, null: false

        t.index %i[finding_id fingerprint_sha256],
          name: FINGERPRINT_IDX,
          unique: true # only one link should exist between occurrence and the fingerprint

        t.index %i[finding_id algorithm_type fingerprint_sha256],
          name: UNIQ_IDX,
          unique: true # these should be unique
      end
    end
  end
end
