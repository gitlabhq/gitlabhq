# LDAP authorization model
#
# * Check if we are allowed access (not blocked)
#
module Gitlab
  module Auth
    module LDAP
      class Access
        attr_reader :provider, :user

        def self.open(user, &block)
          Gitlab::Auth::LDAP::Adapter.open(user.ldap_identity.provider) do |adapter|
            block.call(self.new(user, adapter))
          end
        end

        def self.allowed?(user)
          self.open(user) do |access|
            if access.allowed?
              Users::UpdateService.new(user, user: user, last_credential_check_at: Time.now).execute

              true
            else
              false
            end
          end
        end

        def initialize(user, adapter = nil)
          @adapter = adapter
          @user = user
          @provider = user.ldap_identity.provider
        end

        def allowed?
          if ldap_user
            unless ldap_config.active_directory
              unblock_user(user, 'is available again') if user.ldap_blocked?
              return true
            end

            # Block user in GitLab if he/she was blocked in AD
            if Gitlab::Auth::LDAP::Person.disabled_via_active_directory?(user.ldap_identity.extern_uid, adapter)
              block_user(user, 'is disabled in Active Directory')
              false
            else
              unblock_user(user, 'is not disabled anymore') if user.ldap_blocked?
              true
            end
          else
            # Block the user if they no longer exist in LDAP/AD
            block_user(user, 'does not exist anymore')
            false
          end
        end

        def adapter
          @adapter ||= Gitlab::Auth::LDAP::Adapter.new(provider)
        end

        def ldap_config
          Gitlab::Auth::LDAP::Config.new(provider)
        end

        def ldap_user
          @ldap_user ||= Gitlab::Auth::LDAP::Person.find_by_dn(user.ldap_identity.extern_uid, adapter)
        end

        def block_user(user, reason)
          user.ldap_block

          Gitlab::AppLogger.info(
            "LDAP account \"#{user.ldap_identity.extern_uid}\" #{reason}, " \
            "blocking Gitlab user \"#{user.name}\" (#{user.email})"
          )
        end

        def unblock_user(user, reason)
          user.activate

          Gitlab::AppLogger.info(
            "LDAP account \"#{user.ldap_identity.extern_uid}\" #{reason}, " \
            "unblocking Gitlab user \"#{user.name}\" (#{user.email})"
          )
        end
      end
    end
  end
end
