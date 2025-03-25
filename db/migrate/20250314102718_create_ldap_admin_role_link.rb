# frozen_string_literal: true

class CreateLdapAdminRoleLink < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    create_table :ldap_admin_role_links do |t|
      t.references :member_role,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: true
      t.timestamps_with_timezone null: false
      t.text :provider, limit: 255, null: false
      t.text :cn, limit: 255
      t.text :filter, limit: 255
    end
  end
end
