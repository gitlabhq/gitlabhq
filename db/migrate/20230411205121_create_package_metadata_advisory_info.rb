# frozen_string_literal: true

class CreatePackageMetadataAdvisoryInfo < Gitlab::Database::Migration[2.1]
  def change
    create_table :pm_advisories do |t|
      t.text :advisory_xid, limit: 36, null: false
      t.date :published_date, null: false
      t.timestamps_with_timezone null: false
      t.integer :source_xid, limit: 2, null: false

      t.text :title, limit: 256
      t.text :description, limit: 8192
      t.text :cvss_v2, limit: 128
      t.text :cvss_v3, limit: 128
      t.text :urls, array: true, default: []
      t.jsonb :identifiers, null: false

      t.index [:advisory_xid, :source_xid], unique: true
      t.check_constraint 'CARDINALITY(urls) <= 10'
    end

    create_table :pm_affected_packages do |t|
      t.references :pm_advisory, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.integer :purl_type, limit: 2, null: false

      t.text :package_name, limit: 256, null: false
      t.text :distro_version, limit: 256, null: true
      t.text :solution, limit: 2048, null: true
      t.text :affected_range, limit: 512, null: false
      t.text :fixed_versions, array: true, default: []
      t.jsonb :overridden_advisory_fields, null: false, default: {}

      t.index [:pm_advisory_id, :purl_type, :package_name, :distro_version], unique: true,
        name: 'i_affected_packages_unique_for_upsert'
      t.check_constraint 'CARDINALITY(fixed_versions) <= 10'
    end
  end
end
