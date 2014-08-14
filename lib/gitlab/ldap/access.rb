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
        if Gitlab::LDAP::Person.find_by_dn(user.extern_uid, adapter)
          !Gitlab::LDAP::Person.active_directory_disabled?(user.extern_uid, adapter)
        else
          false
        end
      rescue
        false
      end

      def get_ldap_user(user)
        @ldap_user ||= Gitlab::LDAP::Person.find_by_dn(user.extern_uid)
      end

      def update_permissions(user)
        if Gitlab.config.ldap['sync_ssh_keys']
          update_ssh_keys(user)
        end

        # Skip updating group permissions
        # if instance does not use group_base setting
        return true unless Gitlab.config.ldap['group_base'].present?

        update_ldap_group_links(user)

        if Gitlab.config.ldap['admin_group'].present?
          update_admin_status(user)
        end
      end

      # Update user ssh keys if they changed in LDAP
      def update_ssh_keys(user)
        # Get LDAP user entry
        ldap_user = get_ldap_user(user)

        user.keys.ldap.where.not(key: ldap_user.ssh_keys).each do |deleted_key|
          Rails.logger.info "#{self.class.name}: removing LDAP SSH key #{deleted_key.key} from #{user.name} (#{user.id})"
          unless deleted_key.destroy
            Rails.logger.error "#{self.class.name}: failed to remove LDAP SSH key #{key.inspect} from #{user.name} (#{user.id})"
          end
        end

        (ldap_user.ssh_keys - user.keys.ldap.pluck(:key)).each do |key|
          Rails.logger.info "#{self.class.name}: adding LDAP SSH key #{key.inspect} to #{user.name} (#{user.id})"
          new_key = LDAPKey.new(title: "LDAP - #{Gitlab.config.ldap['sync_ssh_keys']}", key: key)
          new_key.user = user
          unless new_key.save
            Rails.logger.error "#{self.class.name}: failed to add LDAP SSH key #{key.inspect} to #{user.name} (#{user.id})\n"\
              "error messages: #{new_key.errors.messages}"
          end
        end
      end

      # Update user email if it changed in LDAP
      def update_email(user)
        uid = user.extern_uid
        ldap_user = get_ldap_user(user)
        gitlab_user = ::User.where(provider: 'ldap', extern_uid: uid).last

        if gitlab_user && ldap_user && ldap_user.email
          ldap_email = ldap_user.email.last.to_s.downcase

          if (gitlab_user.email != ldap_email)
            gitlab_user.update(email: ldap_email)
          else
            false
          end
        else
          false
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

      def update_admin_status(user)
        admin_group = Gitlab::LDAP::Group.find_by_cn(Gitlab.config.ldap['admin_group'], adapter)
        if admin_group.has_member?(Gitlab::LDAP::Person.find_by_dn(user.extern_uid, adapter))
          unless user.admin?
            user.admin = true
            user.save
          end
        else
          if user.admin?
            user.admin = false
            user.save
          end
        end
      end

      def ldap_groups
        @ldap_groups ||= ::LdapGroupLink.distinct(:cn).pluck(:cn).map do |cn|
          Gitlab::LDAP::Group.find_by_cn(cn, adapter)
        end
      end

      # returns a collection of cn strings to which the user has access
      def cns_with_access(ldap_user)
        @ldap_groups_with_access ||= ldap_groups.select do |ldap_group|
          ldap_group.has_member?(ldap_user)
        end.map(&:cn)
      end

      def gitlab_groups_with_ldap_link
        ::Group.includes(:ldap_group_links).references(:ldap_group_links).
          where.not(ldap_group_links: { id: nil })
      end

      # Loop throug all ldap conneted groups, and update the users link with it
      def update_ldap_group_links(user)
        gitlab_groups_with_ldap_link.each do |group|
          active_group_links = group.ldap_group_links.where(cn: cns_with_access(ldap_user))

          if active_group_links.any?
            group.add_user(user, fetch_group_access(group, user, active_group_links))
          else
            group.users.delete(user) #ensure this is the nice way to do it
          end
        end
      end

      # Get the group_access for a give user.
      # Always respect the current level, never downgrade it.
      def fetch_group_acess(group, user, active_group_links)
        current_access_level = group.users_groups.where(user_id: user).maximum(:group_access)
        max_group_access_level = active_group_links.maximum(:group_access)

        # TODO: Test if nil value of current_access_level in handled properly
        [current_access_level, max_group_access_level].compact.max
      end
    end
  end
end


