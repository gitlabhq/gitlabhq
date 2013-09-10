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

        # Get LDAP user entry
        ldap_user = Gitlab::LDAP::Person.find_by_dn(user.extern_uid)

        # Get all GitLab groups with activated LDAP
        groups = ::Group.where('ldap_cn IS NOT NULL')

        # Get LDAP groups based on cn from GitLab groups
        ldap_groups = groups.pluck(:ldap_cn).map { |cn| Gitlab::LDAP::Group.find_by_cn(cn) }
        ldap_groups = ldap_groups.compact.uniq

        # Iterate over ldap groups and check user membership
        ldap_groups.each do |ldap_group|
          if ldap_group.has_member?(ldap_user)
            # If user present in LDAP group -> add him to GitLab groups
            add_user_to_groups(user.id, ldap_group.cn)
          else
            # If not - remove him from GitLab groups
            remove_user_from_groups(user.id, ldap_group.cn)
          end
        end
      end

      def add_user_to_groups(user_id, group_cn)
        groups = ::Group.where(ldap_cn: group_cn)
        groups.each do |group|
          group.add_users([user_id], group.ldap_access) if group.ldap_access.present?
        end
      end

      def remove_user_from_groups(user_id, group_cn)
        groups = ::Group.where(ldap_cn: group_cn)
        groups.each do |group|
          group.users_groups.where(user_id: user_id).destroy_all
        end
      end
    end
  end
end
