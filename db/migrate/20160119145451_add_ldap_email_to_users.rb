class AddLdapEmailToUsers < ActiveRecord::Migration
  def up
    add_column :users, :ldap_email, :boolean, default: false, null: false

    if Gitlab::Database.mysql?
      execute %{
        UPDATE users, identities
        SET users.ldap_email = TRUE
        WHERE identities.user_id = users.id
        AND users.email LIKE 'temp-email-for-oauth%'
        AND identities.provider LIKE 'ldap%'
        AND identities.extern_uid IS NOT NULL
      }
    else
      execute %{
        UPDATE users
        SET ldap_email = TRUE
        FROM identities
        WHERE identities.user_id = users.id
        AND users.email LIKE 'temp-email-for-oauth%'
        AND identities.provider LIKE 'ldap%'
        AND identities.extern_uid IS NOT NULL
      }
    end
  end

  def down
    remove_column :users, :ldap_email
  end
end
