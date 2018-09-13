class LdapSyncWorker
  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    return unless Gitlab::Auth::LDAP::Config.group_sync_enabled?

    Rails.logger.info "Performing daily LDAP sync task."
    User.ldap.find_each(batch_size: 100).each do |ldap_user|
      Rails.logger.debug "Syncing user #{ldap_user.username}, #{ldap_user.email}"
      # Use the 'update_ldap_group_links_synchronously' option to avoid creating a ton
      # of new Sidekiq jobs all at once.
      Gitlab::Auth::LDAP::Access.allowed?(ldap_user, update_ldap_group_links_synchronously: true)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
