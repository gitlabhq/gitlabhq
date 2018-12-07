# frozen_string_literal: true

module SystemCheck
  module RakeTask
    # Used by gitlab:ldap:check rake task
    class LdapTask
      extend RakeTaskHelpers

      def self.name
        'LDAP'
      end

      def self.checks
        [SystemCheck::LdapCheck]
      end
    end
  end
end
