#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

module Gitlab
  module LDAP
    class Person
      def self.find_by_uid(uid)
        Gitlab::LDAP::Adapter.new.user(config.uid, uid)
      end

      def self.find_by_dn(dn)
        Gitlab::LDAP::Adapter.new.user('dn', dn)
      end

      def initialize(entry)
        @entry = entry
      end

      def name
        entry.cn.join(" ")
      end

      def uid
        entry.send(config.uid).join(" ")
      end

      def username
        uid
      end

      def dn
        entry.dn
      end

      def groups
        adapter.groups.select do |group|
          if group.memberuid?
            group.member_uids.include?(uid)
          else
            group.member_dns.include?(dn)
          end
        end
      end

      private

      def entry
        @entry
      end

      def adapter
        @adapter ||= Gitlab::LDAP::Adapter.new
      end

      def config
        @config ||= Gitlab.config.ldap
      end
    end
  end
end
