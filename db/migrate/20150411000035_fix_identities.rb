class FixIdentities < ActiveRecord::Migration
  def up
    new_provider = Gitlab.config.ldap.servers.first.last['provider_name']
	  # Delete duplicate identities
    Identity.connection.select_one("DELETE FROM identities WHERE provider = 'ldap' AND user_id IN (SELECT user_id FROM identities WHERE provider = '#{new_provider}')")
	  # Update legacy identities
    Identity.where(provider: 'ldap').update_all(provider: new_provider)

    if defined?(LdapGroupLink)
      LdapGroupLink.where('provider IS NULL').update_all(provider: new_provider)
    end
  end

  def down
  end
end
