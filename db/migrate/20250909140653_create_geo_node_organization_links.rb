# frozen_string_literal: true

class CreateGeoNodeOrganizationLinks < Gitlab::Database::Migration[2.3]
  # Because index_geo_node_organization_links_on_geo_node_id_and_organization_id is over the 63 char limit
  INDEX_NAME = :index_geo_node_organization_links_on_geo_node_id_and_org_id

  milestone '18.4'

  def change
    create_table :geo_node_organization_links do |t|
      t.references :geo_node, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :organization, null: false
      t.timestamps_with_timezone null: false
      t.index [:geo_node_id, :organization_id], unique: true, name: INDEX_NAME
    end
  end
end
