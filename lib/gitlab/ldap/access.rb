#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

module Gitlab
  module LDAP
    class Access
      def update_permissions(user)
        # Skip updating group permissions
        # if instance does not use group_base setting
        return true unless Gitlab.config.ldap['group_base'].present?

        ldap_user = Gitlab::LDAP::Person.find(user.extern_uid)
        ldap_groups = ldap_user.groups
        ldap_groups_cn = ldap_groups.map(&:name)
        groups = ::Group.where(ldap_cn: ldap_groups_cn)

        # First lets add user to new groups
        groups.each do |group|
          group.add_users([user.id], group.ldap_access) if group.ldap_access.present?
        end

        # Remove groups with LDAP if user lost access to it
        user.authorized_groups.where('ldap_cn IS NOT NULL').each do |group|
          if ldap_groups_cn.include?(group.ldap_cn)
            # ok user still in group
          else
            # user lost access to this group in ldap
            membership = group.users_groups.where(user_id: user.id).last
            membership.destroy if membership
          end
        end
      end
    end
  end
end
