# frozen_string_literal: true

class CreateCdApplicationLinks < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  UNIQUE_INDEX_NAME = 'index_cd_application_links_on_application_id_and_url'
  ORG_INDEX_NAME = 'index_cd_application_links_on_organization_id'

  def change
    create_table :cd_application_links do |t|
      t.bigint :organization_id, null: false
      t.bigint :application_id, null: false
      t.integer :link_type, null: false, default: 0, limit: 2
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.text :url, null: false, limit: 2048

      t.index [:application_id, :url], unique: true, name: UNIQUE_INDEX_NAME
      t.index :organization_id, name: ORG_INDEX_NAME
    end
  end
end
