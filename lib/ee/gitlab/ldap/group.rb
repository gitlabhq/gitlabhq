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

        def dn
          entry.dn
        end

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
          base = Net::LDAP::DN.new(adapter.config.base.downcase).to_a
          members.select! { |dn| Net::LDAP::DN.new(dn.downcase).to_a.last(base.length) == base }

          members
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
      end
    end
  end
end
