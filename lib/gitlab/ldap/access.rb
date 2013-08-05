#-------------------------------------------------------------------
#
# The GitLab Enterprise Edition (EE) license
#
# Copyright (c) 2013 GitLab.com
#
# All Rights Reserved. No part of this software may be reproduced without
# prior permission of GitLab.com. By using this software you agree to be
# bound by the GitLab Enterprise Support Subscription Terms.
#
#-------------------------------------------------------------------

module Gitlab
  module LDAP
    class Access
      def update_permissions(user)
        ldap_user = Gitlab::LDAP::Person.find(user.extern_uid)
        ldap_groups = ldap_user.groups
        ldap_groups_cn = ldap_groups.map(&:name)
        groups = ::Group.where(ldap_cn: ldap_groups_cn)

        # First lets add user to new groups
        groups.each do |group|
          group.add_users([user.id], UsersGroup::DEVELOPER)
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
