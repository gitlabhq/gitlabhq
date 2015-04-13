class FixIdentities < ActiveRecord::Migration
  def up
    new_provider = Gitlab.config.ldap.servers.first.last['provider_name']

	  # Delete duplicate identities
    execute "DELETE FROM identities WHERE provider = 'ldap' AND user_id IN (SELECT user_id FROM identities WHERE provider = '#{new_provider}')"

    # Update legacy identities
    execute "UPDATE identities SET provider = '#{new_provider}' WHERE provider = 'ldap';"

    if defined?(LdapGroupLink)
      execute "UPDATE ldap_group_links SET provider = '#{new_provider}' WHERE provider IS NULL;"
    end
  end

  def down
  end
end
