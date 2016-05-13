module Gitlab
  module LDAP
    class Person
      # Active Directory-specific LDAP filter that checks if bit 2 of the
      # userAccountControl attribute is set.
      # Source: http://ctogonewild.com/2009/09/03/bitmask-searches-in-ldap/
      AD_USER_DISABLED = Net::LDAP::Filter.ex("userAccountControl:1.2.840.113556.1.4.803", "2")

      attr_accessor :entry, :provider

      def self.find_by_uid(uid, adapter)
        uid = Net::LDAP::Filter.escape(uid)
        adapter.user(adapter.config.uid, uid)
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
        if config.sync_ssh_keys? && entry.respond_to?(config.sync_ssh_keys)
          entry[config.sync_ssh_keys.to_sym].
            map { |key| key[/(ssh|ecdsa)-[^ ]+ [^\s]+/] }.
            compact
        else
          []
        end
      end

      def kerberos_principal
        # The following is only meaningful for Active Directory
        return unless entry.respond_to?(:sAMAccountName)
        entry[:sAMAccountName].first + '@' + windows_domain_name.upcase
      end

      def windows_domain_name
        # The following is only meaningful for Active Directory
        require 'net/ldap/dn'
        dn_components = []
        Net::LDAP::DN.new(dn).each_pair { |name, value| dn_components << { name: name, value: value } }
        dn_components.
          reverse.
          take_while { |rdn| rdn[:name].casecmp('DC').zero? }. # Domain Component
          map { |rdn| rdn[:value] }.
          reverse.
          join('.')
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
