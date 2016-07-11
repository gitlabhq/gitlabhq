module EE
  module Gitlab
    module LDAP
      class Group
        attr_accessor :adapter

        def self.find_by_cn(cn, adapter)
          cn = Net::LDAP::Filter.escape(cn)
          adapter.group(cn)
        end

        def initialize(entry, adapter=nil)
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

        def member_dns
          dns = []

          # There's an edge-case with AD where sometimes a recursive search
          # doesn't return all users at the top-level. Concat recursive results
          # with regular results to be safe. See gitlab-ee#484
          if active_directory?
            dns = adapter.dns_for_filter(active_directory_recursive_memberof_filter)
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

        # We use the ActiveDirectory LDAP_MATCHING_RULE_IN_CHAIN matching rule; see
        # http://msdn.microsoft.com/en-us/library/aa746475%28VS.85%29.aspx#code-snippet-5
        def active_directory_recursive_memberof_filter
          Net::LDAP::Filter.ex("memberOf:1.2.840.113556.1.4.1941", entry.dn)
        end

        def entry
          @entry
        end
      end
    end
  end
end
