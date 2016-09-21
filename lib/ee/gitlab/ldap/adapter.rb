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

        def group_members_in_range(dn, range_start)
          ldap_search(
            base: dn,
            scope: Net::LDAP::SearchScope_BaseObject,
            attributes: ["member;range=#{range_start}-*"],
          ).first
        end

        def nested_groups(parent_dn)
          options = {
            base: config.group_base,
            filter: Net::LDAP::Filter.join(
              Net::LDAP::Filter.eq('objectClass', 'group'),
              Net::LDAP::Filter.eq('memberOf', parent_dn)
            )
          }

          ldap_search(options).map do |entry|
            LDAP::Group.new(entry, self)
          end
        end
      end
    end
  end
end
