# LDAP User EE mixin
#
# This module is intended to encapsulate EE-specific User methods
# and be **prepended** in the `Gitlab::LDAP::User` class.
module EE
  module Gitlab
    module LDAP
      module User
        def initialize(auth_hash)
          super

          with_proxy(auth_hash.provider) do |proxy|
            set_external_with_external_groups(proxy)
          end
        end

        # Intended to be called during #initialize, and #save should be called
        # after initialize.
        def set_external_with_external_groups(proxy)
          gl_user.external = in_any_external_group?(proxy)
        end

        # Returns true if the User is found in an external group listed in the
        # config.
        #
        # Only checks the LDAP provider where the User was authorized.
        def in_any_external_group?(proxy)
          external_groups = proxy.adapter.config.external_groups
          external_groups.any? do |group_cn|
            in_group?(proxy, group_cn)
          end
        end

        # Returns true if the User is a member of the group.
        def in_group?(proxy, group_cn)
          member_dns = proxy.dns_for_group_cn(group_cn)
          member_dns.include?(auth_hash.uid)
        end

        def with_proxy(provider, &block)
          ::EE::Gitlab::LDAP::Sync::Proxy.open(provider, &block)
        end
      end
    end
  end
end
