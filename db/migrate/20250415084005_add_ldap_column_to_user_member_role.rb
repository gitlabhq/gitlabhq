# frozen_string_literal: true

class AddLdapColumnToUserMemberRole < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def change
    add_column :user_member_roles, :ldap, :boolean, null: false, default: false, if_not_exists: true
  end
end
