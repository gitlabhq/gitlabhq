class LdapAllGroupsSyncWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    return unless Gitlab::LDAP::Config.enabled? && ::License.feature_available?(:ldap_group_sync)

    logger.info 'Started LDAP group sync'
    EE::Gitlab::LDAP::Sync::Groups.execute
    logger.info 'Finished LDAP group sync'
  end
end
