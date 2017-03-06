module EE
  module GroupPolicy
    def rules
      raise NotImplementedError unless defined?(super)

      super

      return unless @user

      if @subject.ldap_synced?
        cannot! :admin_group_member
        can! :override_group_member if @user.admin? || @subject.has_owner?(@user)
      end
    end
  end
end
