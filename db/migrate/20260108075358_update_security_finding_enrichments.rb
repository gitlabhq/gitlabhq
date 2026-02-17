# frozen_string_literal: true

class UpdateSecurityFindingEnrichments < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  def change
    change_table :security_finding_enrichments do |t|
      t.float :epss_score, null: true
      t.boolean :is_known_exploit, null: true

      t.index :epss_score, name: 'index_sec_finding_enrichments_on_epss_score', where: 'epss_score IS NOT NULL'
      t.index :is_known_exploit, name: 'index_sec_finding_enrichments_on_is_known_exploit',
        where: 'is_known_exploit IS NOT NULL'
    end
  end
end
