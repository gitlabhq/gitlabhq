class FixIdentities < ActiveRecord::Migration
  def up
    # Up until now, legacy 'ldap' references in the database were charitably
    # interpreted to point to the first LDAP server specified in the GitLab
    # configuration. So if the database said 'provider: ldap' but the first
    # LDAP server was called 'ldapmain', then we would try to interpret
    # 'provider: ldap' as if it said 'provider: ldapmain'. This migration (and
    # accompanying changes in the GitLab LDAP code) get rid of this complicated
    # behavior. Any database references to 'provider: ldap' get rewritten to
    # whatever the code would have interpreted it as, i.e. as a reference to
    # the first LDAP server specified in gitlab.yml / gitlab.rb.
    new_provider = if Gitlab.config.ldap.enabled
                     first_ldap_server = Gitlab.config.ldap.servers.values.first
                     first_ldap_server['provider_name']
                   else
                     'ldapmain'
                   end

    # Delete duplicate identities
    execute "DELETE FROM identities WHERE provider = 'ldap' AND user_id IN (SELECT user_id FROM identities WHERE provider = '#{new_provider}')"

    # Update legacy identities
    execute "UPDATE identities SET provider = '#{new_provider}' WHERE provider = 'ldap';"

    if table_exists?('ldap_group_links')
      execute "UPDATE ldap_group_links SET provider = '#{new_provider}' WHERE provider IS NULL OR provider = 'ldap';"
    end
  end

  def down
  end
end
