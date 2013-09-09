#-------------------------------------------------------------------
#
# Copyright (C) 2013 GitLab.com - Distributed under the MIT Expat License
#
#-------------------------------------------------------------------

module Gitlab
  module LDAP
    class Group
      def initialize(entry)
        @entry = entry
      end

      def name
        entry.cn.join(" ")
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
        if entry.respond_to? :member
          entry.member
        elsif entry.respond_to? :uniquemember
          entry.uniquemember
        elsif entry.respond_to? :memberof
          entry.memberof
        else
          raise 'Unsupported member attribute'
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
