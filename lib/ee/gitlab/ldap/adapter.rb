# LDAP connection adapter EE mixin
#
# This module is intended to encapsulate EE-specific adapter methods
# and be included in the `Gitlab::LDAP::Adapter` class.
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
            filter: Net::LDAP::Filter.eq("cn", cn)
          }

          options.merge!(size: size) if size

          ldap_search(options).map do |entry|
            LDAP::Group.new(entry, self)
          end
        end

        def group(*args)
          groups(*args).first
        end

        def dn_matches_filter?(dn, filter)
          ldap_search(
            base: dn,
            filter: filter,
            scope: Net::LDAP::SearchScope_BaseObject,
            attributes: %w{dn}
          ).any?
        end
      end
    end
  end
end
