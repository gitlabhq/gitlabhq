class LdapAllGroupsSyncWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    return unless Gitlab::LDAP::Config.enabled_extras?

    logger.info 'Started LDAP group sync'
    EE::Gitlab::LDAP::Sync::Groups.execute
    logger.info 'Finished LDAP group sync'
  end
end
