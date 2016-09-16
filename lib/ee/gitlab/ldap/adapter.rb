# LDAP connection adapter EE mixin
#
# This module is intended to encapsulate EE-specific adapter methods
# and be **prepended** in the `Gitlab::LDAP::Adapter` class.
module EE
  module Gitlab
    module LDAP
      module Adapter
        # Get LDAP groups from ou=Groups
        #
        # cn - filter groups by name
        #
        # Ex.
        #   groups("dev*") # return all groups start with 'dev'
        #
        def groups(cn = "*", size = nil)
          options = {
            base: config.group_base,
            filter: Net::LDAP::Filter.eq("cn", cn),
            attributes: %w(dn cn memberuid member submember uniquemember memberof)
          }

          options.merge!(size: size) if size

          ldap_search(options).map do |entry|
            LDAP::Group.new(entry, self)
          end
        end

        def group(*args)
          groups(*args).first
        end

        def dns_for_filter(filter)
          ldap_search(
            base: config.base,
            filter: filter,
            scope: Net::LDAP::SearchScope_WholeSubtree,
            attributes: %w{dn}
          ).map(&:dn)
        end

        def user_attributes
          attributes = super
          attributes << config.sync_ssh_keys if config.sync_ssh_keys
          attributes
        end
      end
    end
  end
end
