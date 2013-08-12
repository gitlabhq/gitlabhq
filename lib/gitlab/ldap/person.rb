#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

module Gitlab
  module LDAP
    class Person
      def self.find(user_uid)
        uid = if user_uid =~ /uid=([a-zA-Z0-9.-]+)/
                $1
              else
                user_uid
              end


        Gitlab::LDAP::Adapter.new.user(uid)
      end

      def initialize(entry)
        @entry = entry
      end

      def name
        entry.cn.join(" ")
      end

      def uid
        entry.uid.join(" ")
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
    end
  end
end
