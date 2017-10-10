class LdapAllGroupsSyncWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    return unless Gitlab::LDAP::Config.group_sync_enabled?

    logger.info 'Started LDAP group sync'
    EE::Gitlab::LDAP::Sync::Groups.execute
    logger.info 'Finished LDAP group sync'
  end
end
