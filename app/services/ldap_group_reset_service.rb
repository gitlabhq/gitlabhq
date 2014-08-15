class LdapGroupResetService
  def execute(group, current_user)
    # Only for ldap connected users
    # reset last_credential_check_at
    # set Gitlab::Access::Guest
    group.members.includes(:user).each do |member|
      user = member.user

      if user.ldap_user? && user != current_user
        member.group_access = group.ldap_access
        member.save
      end
    end
  end
end
