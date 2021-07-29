# frozen_string_literal: true

# LDAP authorization model
#
# * Check if we are allowed access (not blocked)
#
module Gitlab
  module Auth
    module Ldap
      class Access
        attr_reader :provider, :user, :ldap_identity

        def self.open(user, &block)
          Gitlab::Auth::Ldap::Adapter.open(user.ldap_identity.provider) do |adapter|
            block.call(self.new(user, adapter))
          end
        end

        def self.allowed?(user, options = {})
          self.open(user) do |access|
            # Whether user is allowed, or not, we should update
            # permissions to keep things clean
            if access.allowed?
              unless Gitlab::Database.main.read_only?
                access.update_user
                Users::UpdateService.new(user, user: user, last_credential_check_at: Time.now).execute
              end

              true
            else
              false
            end
          end
        end

        def initialize(user, adapter = nil)
          @adapter = adapter
          @user = user
          @ldap_identity = user.ldap_identity
          @provider = adapter&.provider || ldap_identity&.provider
        end

        def allowed?
          if ldap_user
            unless ldap_config.active_directory
              unblock_user(user, 'is available again') if user.ldap_blocked?
              return true
            end

            # Block user in GitLab if they were blocked in AD
            if Gitlab::Auth::Ldap::Person.disabled_via_active_directory?(ldap_identity.extern_uid, adapter)
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
        rescue LdapConnectionError
          false
        end

        def update_user
          # no-op in CE
        end

        private

        def adapter
          @adapter ||= Gitlab::Auth::Ldap::Adapter.new(provider)
        end

        def ldap_config
          Gitlab::Auth::Ldap::Config.new(provider)
        end

        def ldap_user
          return unless provider

          @ldap_user ||= find_ldap_user
        end

        def find_ldap_user
          Gitlab::Auth::Ldap::Person.find_by_dn(ldap_identity.extern_uid, adapter)
        end

        def block_user(user, reason)
          user.ldap_block

          if provider
            Gitlab::AppLogger.info(
              "LDAP account \"#{ldap_identity.extern_uid}\" #{reason}, " \
              "blocking GitLab user \"#{user.name}\" (#{user.email})"
            )
          else
            Gitlab::AppLogger.info(
              "Account is not provided by LDAP, " \
              "blocking GitLab user \"#{user.name}\" (#{user.email})"
            )
          end
        end

        def unblock_user(user, reason)
          user.activate

          Gitlab::AppLogger.info(
            "LDAP account \"#{ldap_identity.extern_uid}\" #{reason}, " \
            "unblocking GitLab user \"#{user.name}\" (#{user.email})"
          )
        end
      end
    end
  end
end

Gitlab::Auth::Ldap::Access.prepend_mod_with('Gitlab::Auth::Ldap::Access')
