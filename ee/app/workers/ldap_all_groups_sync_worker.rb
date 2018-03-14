class LdapAllGroupsSyncWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return unless Gitlab::Auth::LDAP::Config.group_sync_enabled?

    logger.info 'Started LDAP group sync'
    EE::Gitlab::Auth::LDAP::Sync::Groups.execute
    logger.info 'Finished LDAP group sync'
  end
end
