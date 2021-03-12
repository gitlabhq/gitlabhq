# frozen_string_literal: true

class RenameVulnFingerprintsIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  FINGERPRINT_IDX = :idx_vuln_fingerprints_on_occurrences_id_and_fingerprint
  FINGERPRINT_IDX_RENAMED = :idx_vuln_fingerprints_on_occurrences_id_and_fingerprint_sha256
  UNIQ_IDX = :idx_vuln_fingerprints_uniqueness
  UNIQ_IDX_RENAMED = :idx_vuln_fingerprints_uniqueness_fingerprint_sha256

  disable_ddl_transaction!

  def up
    # These `unless` checks are necessary for re-running the migrations multiple times
    unless index_exists_by_name?(:vulnerability_finding_fingerprints, FINGERPRINT_IDX_RENAMED)
      rename_index :vulnerability_finding_fingerprints, FINGERPRINT_IDX, FINGERPRINT_IDX_RENAMED
    end

    unless index_exists_by_name?(:vulnerability_finding_fingerprints, UNIQ_IDX_RENAMED)
      rename_index :vulnerability_finding_fingerprints, UNIQ_IDX, UNIQ_IDX_RENAMED
    end
  end

  def down
    unless index_exists_by_name?(:vulnerability_finding_fingerprints, FINGERPRINT_IDX)
      rename_index :vulnerability_finding_fingerprints, FINGERPRINT_IDX_RENAMED, FINGERPRINT_IDX
    end

    unless index_exists_by_name?(:vulnerability_finding_fingerprints, UNIQ_IDX)
      rename_index :vulnerability_finding_fingerprints, UNIQ_IDX_RENAMED, UNIQ_IDX
    end
  end
end
