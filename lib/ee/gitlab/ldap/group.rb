module EE
  module Gitlab
    module LDAP
      class Group
        attr_accessor :adapter

        def self.find_by_cn(cn, adapter)
          cn = Net::LDAP::Filter.escape(cn)
          adapter.group(cn)
        end

        def initialize(entry, adapter = nil)
          Rails.logger.debug { "Instantiating #{self.class.name} with LDIF:\n#{entry.to_ldif}" }
          @entry = entry
          @adapter = adapter
        end

        def active_directory?
          adapter.config.active_directory
        end

        def cn
          entry.cn.first
        end

        def name
          cn
        end

        def path
          name.parameterize
        end

        def memberuid?
          entry.respond_to? :memberuid
        end

        def member_uids
          entry.memberuid
        end

        delegate :dn, to: :entry

        def member_dns(nested_groups_to_skip = [])
          dns = []

          if active_directory? && adapter
            dns.concat(active_directory_members(entry, nested_groups_to_skip))
          end

          if (entry.respond_to? :member) && (entry.respond_to? :submember)
            dns.concat(entry.member + entry.submember)
          elsif entry.respond_to? :member
            dns.concat(entry.member)
          elsif entry.respond_to? :uniquemember
            dns.concat(entry.uniquemember)
          elsif entry.respond_to? :memberof
            dns.concat(entry.memberof)
          else
            Rails.logger.warn("Could not find member DNs for LDAP group #{entry.inspect}")
          end

          dns.uniq
        end

        private

        def entry
          @entry
        end

        # Active Directory range member methods

        def has_member_range?(entry)
          member_range_attribute(entry).present?
        end

        def member_range_attribute(entry)
          entry.attribute_names.find { |a| a.to_s.start_with?("member;range=")}.to_s
        end

        def active_directory_members(entry, nested_groups_to_skip)
          require 'net/ldap/dn'

          members = []

          # Retrieve all member pages/ranges
          members.concat(ranged_members(entry)) if has_member_range?(entry)
          # Process nested group members
          members.concat(nested_members(nested_groups_to_skip))
          # Clean dns of groups and users outside the base
          members.reject! { |dn| nested_groups_to_skip.include?(dn) }

          return [] if members.empty?

          # Only return members within our given base
          members_within_base(members)
        end

        # AD requires use of range retrieval for groups with more than 1500 members
        # cf. https://msdn.microsoft.com/en-us/library/aa367017(v=vs.85).aspx
        def ranged_members(entry)
          members = []

          # Concatenate the members in the current range
          members.concat(entry[member_range_attribute(entry)])

          # Recursively concatenate members until end of ranges
          if has_more_member_ranges?(entry)
            next_entry = adapter.group_members_in_range(dn, next_member_range_start(entry))

            members.concat(ranged_members(next_entry))
          end

          members
        end

        # Process any AD nested groups. Use a manual process because
        # the AD recursive member of filter is too slow and uses too
        # much CPU on the AD server.
        def nested_members(nested_groups_to_skip)
          # Ignore this group if we see it again in a nested group.
          # Prevents infinite loops.
          nested_groups_to_skip << dn

          members = []
          nested_groups = adapter.nested_groups(dn)

          nested_groups.each do |nested_group|
            next if nested_groups_to_skip.include?(nested_group.dn)

            members.concat(nested_group.member_dns(nested_groups_to_skip))
          end

          members
        end

        def has_more_member_ranges?(entry)
          next_member_range_start(entry).present?
        end

        def next_member_range_start(entry)
          match = member_range_attribute(entry).match /^member;range=\d+-(\d+|\*)$/

          match[1].to_i + 1 if match.present? && match[1] != '*'
        end

        # The old AD recursive member filter would exclude any members that
        # were outside the given search base. To maintain that behavior,
        # we need to do the same.
        #
        # Split the base and each member DN into pairs. Compare the last
        # base N pairs of the member DN. If they match, the user is within
        # the base DN.
        #
        # Ex.
        # - Member DN: 'uid=user,ou=users,dc=example,dc=com'
        # - Base DN:   'dc=example,dc=com'
        #
        # Base has 2 pairs ([dc,example], [dc,com]). If the last 2 pairs of
        # the user DN match, profit!
        def members_within_base(members)
          begin
            base = Net::LDAP::DN.new(adapter.config.base.downcase).to_a
          rescue RuntimeError
            Rails.logger.error "Configured LDAP `base` is invalid: '#{adapter.config.base}'"
            return []
          end

          members.select do |dn|
            begin
              Net::LDAP::DN.new(dn.downcase).to_a.last(base.length) == base
            rescue RuntimeError
              Rails.logger.warn "Received invalid member DN from LDAP group '#{cn}': '#{dn}'. Skipping"
            end
          end
        end
      end
    end
  end
end
