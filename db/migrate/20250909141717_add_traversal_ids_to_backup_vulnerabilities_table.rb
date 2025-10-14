# frozen_string_literal: true

class AddTraversalIdsToBackupVulnerabilitiesTable < Gitlab::Database::Migration[2.3]
  INDEX_NAME = :index_backup_vulnerabilities_for_restoring

  milestone '18.5'

  def change
    change_table :backup_vulnerabilities do |t|
      t.bigint :traversal_ids, array: true, default: [], null: false

      t.index %i[traversal_ids original_record_identifier], name: INDEX_NAME
    end
  end
end
