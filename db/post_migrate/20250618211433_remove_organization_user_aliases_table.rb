# frozen_string_literal: true

class RemoveOrganizationUserAliasesTable < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    drop_table :organization_user_aliases do |t|
      t.belongs_to :organization, null: false, index: false
      t.belongs_to :user, null: false

      # rubocop:disable Migration/PreventStrings -- strings already present in table
      t.string :username, null: false
      t.string :display_name
      # rubocop:enable Migration/PreventStrings

      t.timestamps_with_timezone null: false

      t.index %i[organization_id user_id], unique: true, name: 'unique_organization_user_alias_organization_id_user_id'
      t.index %i[organization_id username], unique: true,
        name: 'unique_organization_user_alias_organization_id_username'
    end
  end
end
