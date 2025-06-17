# frozen_string_literal: true

class AddOrganizationUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    create_table :organization_user_details do |t|
      t.belongs_to :organization, null: false, index: false
      t.belongs_to :user, null: false

      t.text :username, null: false, limit: 510
      t.text :display_name, null: false, limit: 510

      t.timestamps_with_timezone null: false

      t.index [:organization_id, :user_id], unique: true,
        name: :unique_organization_user_details_organization_id_user_id
      t.index [:organization_id, :username], unique: true,
        name: :unique_organization_user_details_organization_id_username
      t.index 'lower(username)'
    end
  end
end
