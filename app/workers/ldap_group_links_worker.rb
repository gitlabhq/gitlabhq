class LdapGroupLinksWorker
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    logger.info "Updating LDAP group memberships for user #{user.id} (#{user.username})"
    access = Gitlab::LDAP::Access.new(user)
    access.update_ldap_group_links
  end
end
