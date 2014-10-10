# LDAP authorization model
#
# * Check if we are allowed access (not blocked)
# * Update authorizations and associations
#
module Gitlab
  module LDAP
    class Access
      attr_reader :adapter, :provider, :user, :ldap_user

      def self.open(user, &block)
        Gitlab::LDAP::Adapter.open(user.provider) do |adapter|
          block.call(self.new(user, adapter))
        end
      end

      def self.allowed?(user)
        self.open(user) do |access|
          if access.allowed?
            access.update_permissions
            access.update_email
            user.last_credential_check_at = Time.now
            user.save
            true
          else
            false
          end
        end
      end

      def initialize(user, adapter=nil)
        @adapter = adapter
        @user = user
        @provider = user.provider
      end

      def allowed?
        if Gitlab::LDAP::Person.find_by_dn(user.extern_uid, adapter)
          return true unless ldap_config.active_directory
          !Gitlab::LDAP::Person.disabled_via_active_directory?(user.extern_uid, adapter)
        else
          false
        end
      rescue
        false
      end

      def adapter
        @adapter ||= Gitlab::LDAP::Adapter.new(provider)
      end

      def ldap_user
        @ldap_user ||= Gitlab::LDAP::Person.find_by_dn(user.extern_uid, adapter)
      end

      def update_permissions
        if sync_ssh_keys?
          update_ssh_keys
        end

        # Skip updating group permissions
        # if instance does not use group_base setting
        return true unless group_base.present?

        update_ldap_group_links

        if admin_group.present?
          update_admin_status
        end
      end

      # Update user ssh keys if they changed in LDAP
      def update_ssh_keys
        user.keys.ldap.where.not(key: ldap_user.ssh_keys).each do |deleted_key|
          Rails.logger.info "#{self.class.name}: removing LDAP SSH key #{deleted_key.key} from #{user.name} (#{user.id})"
          unless deleted_key.destroy
            Rails.logger.error "#{self.class.name}: failed to remove LDAP SSH key #{key.inspect} from #{user.name} (#{user.id})"
          end
        end

        (ldap_user.ssh_keys - user.keys.ldap.pluck(:key)).each do |key|
          Rails.logger.info "#{self.class.name}: adding LDAP SSH key #{key.inspect} to #{user.name} (#{user.id})"
          new_key = LDAPKey.new(title: "LDAP - #{ldap_config.sync_ssh_keys}", key: key)
          new_key.user = user
          unless new_key.save
            Rails.logger.error "#{self.class.name}: failed to add LDAP SSH key #{key.inspect} to #{user.name} (#{user.id})\n"\
              "error messages: #{new_key.errors.messages}"
          end
        end
      end

      # Update user email if it changed in LDAP
      def update_email
        if ldap_user.try(:email)
          ldap_email = ldap_user.email.last.to_s.downcase

          if (user.email != ldap_email)
            user.update(email: ldap_email)
          else
            false
          end
        else
          false
        end
      end

      def update_admin_status
        admin_group = Gitlab::LDAP::Group.find_by_cn(ldap_config.admin_group, adapter)
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

      # Loop throug all ldap conneted groups, and update the users link with it
      def update_ldap_group_links
        gitlab_groups_with_ldap_link.each do |group|
          active_group_links = group.ldap_group_links.where(cn: cns_with_access)

          if active_group_links.any?
            group.add_users([user.id], fetch_group_access(group, user, active_group_links))
          else
            group.users.delete(user)
          end
        end
      end

      def ldap_groups
        @ldap_groups ||= ::LdapGroupLink.distinct(:cn).pluck(:cn).map do |cn|
          Gitlab::LDAP::Group.find_by_cn(cn, adapter)
        end.compact
      end

      # returns a collection of cn strings to which the user has access
      def cns_with_access
        @ldap_groups_with_access ||= ldap_groups.select do |ldap_group|
          ldap_group.has_member?(ldap_user)
        end.map(&:cn)
      end

      def ldap_config
        Gitlab::LDAP::Config.new(provider)
      end

      def sync_ssh_keys?
        ldap_config.sync_ssh_keys?
      end

      def group_base
        ldap_config.group_base
      end

      def admin_group
        ldap_config.admin_group
      end

      private
      def gitlab_groups_with_ldap_link
        ::Group.includes(:ldap_group_links).references(:ldap_group_links).
          where.not(ldap_group_links: { id: nil })
      end

      # Get the group_access for a give user.
      # Always respect the current level, never downgrade it.
      def fetch_group_access(group, user, active_group_links)
        current_access_level = group.group_members.where(user_id: user).maximum(:access_level)
        max_group_access_level = active_group_links.maximum(:group_access)

        # TODO: Test if nil value of current_access_level in handled properly
        [current_access_level, max_group_access_level].compact.max
      end
    end
  end
end


