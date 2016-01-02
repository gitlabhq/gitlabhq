class LdapGroupResetService
  def execute(group, current_user)
    # Only for ldap connected users
    # reset last_credential_check_at to force LDAP::Access::update_permissions
    # set Gitlab::Access::Guest to later on upgrade the access of a user

    # trigger the lowest access possible for all LDAP connected users
    group.members.with_ldap_dn.map do |member|
      # don't unauthorize the current user
      next if current_user == member.user
      member.update_attribute :access_level, Gitlab::Access::GUEST
    end

    group.users.ldap.update_all last_credential_check_at: nil
  end
end
