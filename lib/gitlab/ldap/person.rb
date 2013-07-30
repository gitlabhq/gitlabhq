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
    class Person
      def initialize(entry)
        @entry = entry
      end

      def name
        entry.cn.join(" ")
      end

      def username
        entry.uid.join(" ")
      end

      private

      def entry
        @entry
      end
    end
  end
end
