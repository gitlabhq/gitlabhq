desc "GITLAB | migrate provider names to multiple ldap setup"
namespace :gitlab do
  task migrate_ldap_providers: :environment do
    config = Gitlab::LDAP::Config
    raise 'No LDAP server hash defined. See config/gitlab.yml.example for an example' unless config.servers.any?

    provider = config.servers.first['provider_name']
    valid_providers = config.providers
    unmigrated_group_links = LdapGroupLink.where('provider IS NULL OR provider NOT IN (?)', config.providers)
    puts "found #{unmigrated_group_links.count} unmigrated LDAP links"
    puts "setting provider to #{provider}"
    unmigrated_group_links.update_all provider: provider

    unmigrated_ldap_identities = Identity.where(provider: 'ldap')
    puts "found #{unmigrated_ldap_identities.count} unmigrated LDAP users"
    puts "setting provider to #{provider}"
    unmigrated_ldap_identities.update_all provider: provider
  end
end
