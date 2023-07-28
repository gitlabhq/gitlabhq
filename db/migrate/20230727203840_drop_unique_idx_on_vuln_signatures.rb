# frozen_string_literal: true

class DropUniqueIdxOnVulnSignatures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_vuln_signatures_on_occurrences_id_and_signature_sha'

  def up
    remove_concurrent_index_by_name :vulnerability_finding_signatures, INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerability_finding_signatures, %i[finding_id signature_sha], unique: true, name: INDEX_NAME
  end
end
