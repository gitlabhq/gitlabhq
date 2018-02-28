# LDAP User EE mixin
#
# This module is intended to encapsulate EE-specific User methods
# and be **prepended** in the `Gitlab::Auth::LDAP::User` class.
module EE
  module Gitlab
    module Auth
      module LDAP
        module User
          def initialize(auth_hash)
            super

            set_external_with_external_groups
          end

          private

          # Intended to be called during #initialize, and #save should be called
          # after initialize.
          def set_external_with_external_groups
            return if ldap_config.external_groups.empty?

            gl_user.external = in_any_external_group?
          end

          # Returns true if the User is found in an external group listed in the
          # config.
          def in_any_external_group?
            with_proxy do |proxy|
              external_groups = proxy.adapter.config.external_groups
              external_groups.any? do |group_cn|
                in_group?(group_cn, proxy)
              end
            end
          end

          # Returns true if the User is a member of the group.
          def in_group?(group_cn, proxy)
            member_dns = proxy.dns_for_group_cn(group_cn)
            member_dns.include?(auth_hash.uid)
          end

          def with_proxy(&block)
            ::EE::Gitlab::Auth::LDAP::Sync::Proxy.open(auth_hash.provider, &block)
          end
        end
      end
    end
  end
end
