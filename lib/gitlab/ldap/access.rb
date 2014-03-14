#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

module Gitlab
  module LDAP
    class Access
      attr_reader :adapter

      def self.open(&block)
        Gitlab::LDAP::Adapter.open do |adapter|
          block.call(self.new(adapter))
        end
      end

      def initialize(adapter=nil)
        @adapter = adapter
      end

      def allowed?(user)
        !!Gitlab::LDAP::Person.find_by_dn(user.extern_uid, adapter)
      rescue
        false
      end

      def update_permissions(user)
        # Skip updating group permissions
        # if instance does not use group_base setting
        return true unless Gitlab.config.ldap['group_base'].present?

        # Get LDAP user entry
        ldap_user = Gitlab::LDAP::Person.find_by_dn(user.extern_uid, adapter)

        # Get all GitLab groups with activated LDAP
        groups = ::Group.where('ldap_cn IS NOT NULL')

        # Get LDAP groups based on cn from GitLab groups
        ldap_groups = groups.pluck(:ldap_cn).map { |cn| Gitlab::LDAP::Group.find_by_cn(cn, adapter) }
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

      # Add user to GitLab group
      # In case user already exists: update his access level
      # only if existing permissions are lower than ldap one.
      def add_user_to_groups(user_id, group_cn)
        groups = ::Group.where(ldap_cn: group_cn)
        groups.each do |group|
          next unless group.ldap_access.present?

          group_access = group.users_groups.find_by_user_id(user_id)
          next if group_access && group_access.group_access >= group.ldap_access

          group.add_users([user_id], group.ldap_access)
        end
      end

      # Remove user from GitLab group
      def remove_user_from_groups(user_id, group_cn)
        groups = ::Group.where(ldap_cn: group_cn)
        groups.each do |group|
          group.users_groups.where(user_id: user_id).destroy_all
        end
      end
    end
  end
end
