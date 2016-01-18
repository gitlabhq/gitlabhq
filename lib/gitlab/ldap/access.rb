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
        Gitlab::LDAP::Adapter.open(user.ldap_identity.provider) do |adapter|
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
        @provider = user.ldap_identity.provider
      end

      def allowed?
        if ldap_user
          return true unless ldap_config.active_directory

          # Block user in GitLab if he/she was blocked in AD
          if Gitlab::LDAP::Person.disabled_via_active_directory?(user.ldap_identity.extern_uid, adapter)
            user.ldap_block
            false
          else
            user.activate if user.ldap_blocked?
            true
          end
        else
          # Block the user if they no longer exist in LDAP/AD
          user.ldap_block
          false
        end
      rescue
        false
      end

      def adapter
        @adapter ||= Gitlab::LDAP::Adapter.new(provider)
      end

      def ldap_config
        Gitlab::LDAP::Config.new(provider)
      end

      def ldap_user
        @ldap_user ||= Gitlab::LDAP::Person.find_by_dn(user.ldap_identity.extern_uid, adapter)
      end

      def update_permissions
        if sync_ssh_keys?
          update_ssh_keys
        end

        update_kerberos_identity if import_kerberos_identities?

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
        remove_old_ssh_keys
        add_new_ssh_keys
      end

      # Add ssh keys that are in LDAP but not in GitLab
      def add_new_ssh_keys
        keys = ldap_user.ssh_keys - user.keys.ldap.pluck(:key)

        keys.each do |key|
          logger.info "#{self.class.name}: adding LDAP SSH key #{key.inspect} to #{user.name} (#{user.id})"
          new_key = LDAPKey.new(title: "LDAP - #{ldap_config.sync_ssh_keys}", key: key)
          new_key.user = user

          unless new_key.save
            logger.error "#{self.class.name}: failed to add LDAP SSH key #{key.inspect} to #{user.name} (#{user.id})\n"\
              "error messages: #{new_key.errors.messages}"
          end
        end
      end

      # Remove ssh keys that do not exist in LDAP any more
      def remove_old_ssh_keys
        keys = user.keys.ldap.where.not(key: ldap_user.ssh_keys)

        keys.each do |deleted_key|
          logger.info "#{self.class.name}: removing LDAP SSH key #{deleted_key.key} from #{user.name} (#{user.id})"

          unless deleted_key.destroy
            logger.error "#{self.class.name}: failed to remove LDAP SSH key #{key.inspect} from #{user.name} (#{user.id})"
          end
        end
      end

      # Update user Kerberos identity with Kerberos principal name from Active Directory
      def update_kerberos_identity
        # there can be only one Kerberos identity in GitLab; if the user has a Kerberos identity in AD,
        # replace any existing Kerberos identity for the user
        return unless ldap_user.kerberos_principal.present?
        kerberos_identity = user.identities.where(provider: :kerberos).first
        return if kerberos_identity && kerberos_identity.extern_uid == ldap_user.kerberos_principal
        kerberos_identity ||= Identity.new(provider: :kerberos, user: user)
        kerberos_identity.extern_uid = ldap_user.kerberos_principal
        unless kerberos_identity.save
          Rails.logger.error "#{self.class.name}: failed to add Kerberos principal #{principal} to #{user.name} (#{user.id})\n"\
            "error messages: #{new_identity.errors.messages}"
        end
      end

      # Update user email if it changed in LDAP
      def update_email
        return false unless ldap_user.try(:email)

        ldap_email = ldap_user.email.last.to_s.downcase

        return false if user.email == ldap_email

        user.skip_reconfirmation!
        user.update(email: ldap_email)
      end

      def update_admin_status
        admin_group = Gitlab::LDAP::Group.find_by_cn(ldap_config.admin_group, adapter)
        admin_user = Gitlab::LDAP::Person.find_by_dn(user.ldap_identity.extern_uid, adapter)

        if admin_group && admin_group.has_member?(admin_user)
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

      # Loop through all ldap connected groups, and update the users link with it
      #
      # We documented what sort of queries an LDAP server can expect from
      # GitLab EE in doc/integration/ldap.md. Please remember to update that
      # documentation if you change the algorithm below.
      def update_ldap_group_links
        gitlab_groups_with_ldap_link.each do |group|
          active_group_links = group.ldap_group_links.where(cn: cns_with_access)

          if active_group_links.any?
            group.add_users([user.id], active_group_links.maximum(:group_access), skip_notification: true)
          elsif group.last_owner?(user)
            logger.warn "#{self.class.name}: LDAP group sync cannot remove #{user.name} (#{user.id}) from group #{group.name} (#{group.id}) as this is the group's last owner"
          else
            group.users.delete(user)
          end
        end
      end

      def ldap_groups
        @ldap_groups ||= ::LdapGroupLink.with_provider(provider).distinct(:cn).pluck(:cn).map do |cn|
          Gitlab::LDAP::Group.find_by_cn(cn, adapter)
        end.compact
      end

      # returns a collection of cn strings to which the user has access
      def cns_with_access
        @ldap_groups_with_access ||= ldap_groups.select do |ldap_group|
          ldap_group.has_member?(ldap_user)
        end.map(&:cn)
      end

      def sync_ssh_keys?
        ldap_config.sync_ssh_keys?
      end

      def import_kerberos_identities?
        # Kerberos may be enabled for Git HTTP access and/or as an Omniauth provider
        ldap_config.active_directory && (Gitlab.config.kerberos.enabled || AuthHelper.kerberos_enabled? )
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
          where.not(ldap_group_links: { id: nil }).
          where(ldap_group_links: { provider: provider })
      end

      def logger
        Rails.logger
      end
    end
  end
end
