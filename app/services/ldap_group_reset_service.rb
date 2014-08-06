class LdapGroupResetService
  def execute(group, current_user)
    group.members.includes(:user).each do |member|
      user = member.user

      if user.ldap_user? && user != current_user
        member.group_access = group.ldap_access
        member.save
      end
    end
  end
end
