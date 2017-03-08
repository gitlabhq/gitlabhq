module Gitlab
  module LDAP
    class Person
      include EE::Gitlab::LDAP::Person

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
        attribute_value(:name).first
      end

      def uid
        entry.send(config.uid).first
      end

      def username
        uid
      end

      def email
        attribute_value(:email)
      end

      delegate :dn, to: :entry

      private

      def entry
        @entry
      end

      def config
        @config ||= Gitlab::LDAP::Config.new(provider)
      end

      # Using the LDAP attributes configuration, find and return the first
      # attribute with a value. For example, by default, when given 'email',
      # this method looks for 'mail', 'email' and 'userPrincipalName' and
      # returns the first with a value.
      def attribute_value(attribute)
        attributes = Array(config.attributes[attribute.to_s])
        selected_attr = attributes.find { |attr| entry.respond_to?(attr) }

        return nil unless selected_attr

        entry.public_send(selected_attr)
      end
    end
  end
end
