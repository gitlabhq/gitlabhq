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
        Rails.logger.debug { "Instantiating #{self.class.name} with LDIF:\n#{entry.to_ldif}" }
        @entry = entry
      end

      def name
        entry.cn.first
      end

      def uid
        entry.send(config.uid).first
      end

      def username
        uid
      end

      def dn
        entry.dn
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
