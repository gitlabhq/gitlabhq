# frozen_string_literal: true

class CreateSecurityFindingEnrichments < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def up
    create_table :security_finding_enrichments, if_not_exists: true do |t|
      t.uuid :finding_uuid, null: false
      t.bigint :project_id, null: false
      t.bigint :cve_enrichment_id, null: true
      t.timestamps_with_timezone null: false
      t.text :cve, null: false, limit: 24

      t.index :project_id, name: 'index_sec_finding_enrichments_on_project_id'
      t.index :cve_enrichment_id, name: 'index_sec_finding_enrichments_on_cve_enrichment_id'
      t.index :created_at, name: 'index_sec_finding_enrichments_on_created_at'
      t.index [:finding_uuid, :cve],
        unique: true,
        name: 'index_sec_finding_enrichments_on_finding_and_cve'
    end
  end

  def down
    drop_table :security_finding_enrichments
  end
end
