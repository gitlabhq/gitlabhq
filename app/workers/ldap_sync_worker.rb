class LdapSyncWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform
    return unless Gitlab.config.ldap.enabled
    Rails.logger.info "Performing daily LDAP sync task."
    User.ldap.find_each(batch_size: 100).each do |ldap_user|
      Rails.logger.debug "Syncing user #{ldap_user.username}, #{ldap_user.email}"
      # Use the 'update_ldap_group_links_synchronously' option to avoid creating a ton
      # of new Sidekiq jobs all at once.
      Gitlab::LDAP::Access.allowed?(ldap_user, update_ldap_group_links_synchronously: true)
    end
  end
end
