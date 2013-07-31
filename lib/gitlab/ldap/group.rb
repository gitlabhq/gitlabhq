#-------------------------------------------------------------------
#
# The GitLab Enterprise Edition (EE) license
#
# Copyright (c) 2013 GitLab.com
#
# All Rights Reserved. No part of this software may be reproduced without
# prior permission of GitLab.com. By using this software you agree to be
# bound by the GitLab Enterprise Support Subscription Terms.
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

      def members
        member_uids.map do |uid|
          adapter.user(uid)
        end.compact
      end

      def member_uids
        if entry.respond_to? :memberuid
          entry.memberuid
        else
          member_dns.map do |dn|
            $1 if dn =~ /uid=([a-zA-Z0-9.-]+)/
          end
        end.compact
      end

      private

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

      def entry
        @entry
      end

      def adapter
        @adapter ||= Gitlab::LDAP::Adapter.new
      end
    end
  end
end
