# frozen_string_literal: true

class DropVulnerabilitiesAdvisories < Gitlab::Database::Migration[2.1]
  def up
    drop_table :vulnerability_advisories
  end

  def down
    create_table :vulnerability_advisories, id: false do |t|
      t.uuid :uuid, null: false
      t.timestamps_with_timezone null: false
      t.primary_key :id
      t.date :created_date, null: false
      t.date :published_date, null: false
      t.text :description, limit: 2048
      t.text :title, limit: 2048
      t.text :component_name, limit: 2048
      t.text :solution, limit: 2048
      t.text :not_impacted, limit: 2048
      t.text :cvss_v2, limit: 128
      t.text :cvss_v3, limit: 128
      t.text :affected_range, limit: 32
      t.text :identifiers, array: true, default: []
      t.text :fixed_versions, array: true, default: []
      t.text :urls, array: true, default: []
      t.text :links, array: true, default: []
    end
  end
end
