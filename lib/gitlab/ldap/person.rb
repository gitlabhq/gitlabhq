#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

module Gitlab
  module LDAP
    class Person
      def self.find(user_uid)
        id = user_uid.split(",").first
        key, value = id.split("=")
        Gitlab::LDAP::Adapter.new.user(key => value)
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

      def groups
        adapter.groups.select do |group|
          group.member_uids.include?(uid)
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
