# LDAP authorization model
#
# * Check if we are allowed access (not blocked)
#
module Gitlab
  module LDAP
    class Access
      attr_reader :provider, :user

      def self.open(user, &block)
        Gitlab::LDAP::Adapter.open(user.ldap_identity.provider) do |adapter|
          block.call(self.new(user, adapter))
        end
      end

      def self.allowed?(user)
        self.open(user) do |access|
          if access.allowed?
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
    end
  end
end
