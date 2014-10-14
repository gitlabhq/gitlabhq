module Gitlab
  module LDAP
    class Person
      # Active Directory-specific LDAP filter that checks if bit 2 of the
      # userAccountControl attribute is set.
      # Source: http://ctogonewild.com/2009/09/03/bitmask-searches-in-ldap/
      AD_USER_DISABLED = Net::LDAP::Filter.ex("userAccountControl:1.2.840.113556.1.4.803", "2")

<<<<<<< HEAD
      def self.find_by_uid(uid, adapter=nil)
        adapter ||= Gitlab::LDAP::Adapter.new
        adapter.user(Gitlab.config.ldap.uid, uid)
=======
      attr_accessor :entry, :provider

      def self.find_by_uid(uid, adapter)
        adapter.user(adapter.config.uid, uid)
>>>>>>> master
      end

      def self.find_by_dn(dn, adapter)
        adapter.user('dn', dn)
      end

      def self.disabled_via_active_directory?(dn, adapter)
        adapter.dn_matches_filter?(dn, AD_USER_DISABLED)
      end

      def initialize(entry, provider)
        Rails.logger.debug { "Instantiating #{self.class.name} with LDIF:\n#{entry.to_ldif}" }
        @entry = entry
        @provider = provider
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

      def email
        entry.try(:mail)
      end

      def dn
        entry.dn
      end

      def ssh_keys
        ssh_keys_attribute = Gitlab.config.ldap['sync_ssh_keys'].to_sym
        if entry.respond_to?(ssh_keys_attribute)
          entry[ssh_keys_attribute]
        else
          []
        end
      end

      private

      def entry
        @entry
      end

      def config
        @config ||= Gitlab::LDAP::Config.new(provider)
      end
    end
  end
end
