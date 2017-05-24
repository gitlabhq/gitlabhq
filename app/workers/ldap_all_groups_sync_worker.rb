class LdapAllGroupsSyncWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    logger.info 'Started LDAP group sync'
    EE::Gitlab::LDAP::Sync::Groups.execute
    logger.info 'Finished LDAP group sync'
  end
end
