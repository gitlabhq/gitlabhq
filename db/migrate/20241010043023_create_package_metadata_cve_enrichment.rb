# frozen_string_literal: true

class CreatePackageMetadataCveEnrichment < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    create_table :pm_cve_enrichment do |t|
      t.float :epss_score, null: false
      t.timestamps_with_timezone null: false
      t.text :cve, limit: 24, null: false, index: { unique: true }
    end
  end
end
