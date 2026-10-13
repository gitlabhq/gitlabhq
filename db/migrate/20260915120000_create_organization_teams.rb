# frozen_string_literal: true

class CreateOrganizationTeams < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    create_table :organization_teams do |t|
      t.references :organization,
        null: false,
        index: false,
        foreign_key: { to_table: :organizations, on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.text :path, null: false, limit: 255
      t.text :description, limit: 2048

      t.index 'organization_id, LOWER(path)',
        unique: true,
        name: 'uniq_idx_organization_teams_on_org_id_and_lower_path'
      t.index 'organization_id, LOWER(name)',
        unique: true,
        name: 'uniq_idx_organization_teams_on_org_id_and_lower_name'
    end
  end
end
