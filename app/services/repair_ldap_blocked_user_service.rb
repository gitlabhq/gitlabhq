class RepairLdapBlockedUserService
  attr_accessor :user, :identity

  def initialize(user, identity)
    @user, @identity = user, identity
  end

  def execute
    if identity.destroyed?
      user.block if identity.is_ldap? && user.ldap_blocked? && !user.ldap_user?
    else
      user.block if !identity.is_ldap? && user.ldap_blocked? && !user.ldap_user?
    end
  end
end
