class LdapGroupSyncWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(group_id = nil)
    if group_id
      group = Group.find_by(id: group_id)
      unless group
        logger.warn "Could not find group #{group_id} for LDAP group sync"
        return
      end

      logger.info "Started LDAP group sync for group #{group.name} (#{group.id})"
      EE::Gitlab::LDAP::Sync::Group.execute_all_providers(group)
      logger.info "Finished LDAP group sync for group #{group.name} (#{group.id})"
    else
      logger.info 'Started LDAP group sync'
      EE::Gitlab::LDAP::Sync::Groups.execute
      logger.info 'Finished LDAP group sync'
    end
  end
end
