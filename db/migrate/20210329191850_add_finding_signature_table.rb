# frozen_string_literal: true

class AddFindingSignatureTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  SIGNATURE_IDX = :idx_vuln_signatures_on_occurrences_id_and_signature_sha
  UNIQ_IDX = :idx_vuln_signatures_uniqueness_signature_sha

  def up
    with_lock_retries do
      create_table :vulnerability_finding_signatures do |t|
        t.references :finding,
          index: true,
          null: false,
          foreign_key: { to_table: :vulnerability_occurrences, column: :finding_id, on_delete: :cascade }

        t.timestamps_with_timezone null: false

        t.integer :algorithm_type, null: false, limit: 2
        t.binary :signature_sha, null: false

        t.index %i[finding_id signature_sha],
          name: SIGNATURE_IDX,
          unique: true # only one link should exist between occurrence and the signature

        t.index %i[finding_id algorithm_type signature_sha],
          name: UNIQ_IDX,
          unique: true # these should be unique
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :vulnerability_finding_signatures
    end
  end
end
