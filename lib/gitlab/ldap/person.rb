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

      def self.find_by_email(email, adapter)
        email_fields = adapter.config.attributes['email']

        adapter.user(email_fields, email)
      end

      def self.disabled_via_active_directory?(dn, adapter)
        adapter.dn_matches_filter?(dn, AD_USER_DISABLED)
      end

      def self.ldap_attributes(config)
        [
          'dn', # Used in `dn`
          config.uid, # Used in `uid`
          *config.attributes['name'], # Used in `name`
          *config.attributes['email'] # Used in `email`
        ]
      end

      # Returns the UID or DN in a normalized form
      def self.normalize_uid_or_dn(uid_or_dn)
        if is_dn?(uid_or_dn)
          normalize_dn(uid_or_dn)
        else
          normalize_uid(uid_or_dn)
        end
      end

      # Returns true if the string looks like a DN rather than a UID.
      #
      # An empty string is technically a valid DN (null DN), although we should
      # never need to worry about that.
      def self.is_dn?(uid_or_dn)
        uid_or_dn.blank? || uid_or_dn.include?('=')
      end

      # Returns the UID in a normalized form.
      #
      # 1. Excess spaces are stripped
      # 2. The string is downcased (for case-insensitivity)
      def self.normalize_uid(uid)
        normalize_dn_part(uid)
      end

      # Returns the DN in a normalized form.
      #
      # 1. Excess spaces around attribute names and values are stripped
      # 2. The string is downcased (for case-insensitivity)
      def self.normalize_dn(dn)
        dn.split(/([,+=])/).map do |part|
          normalize_dn_part(part)
        end.join('')
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
        entry.public_send(config.uid).first # rubocop:disable GitlabSecurity/PublicSend
      end

      def username
        uid
      end

      def email
        attribute_value(:email)
      end

      def dn
        self.class.normalize_dn(entry.dn)
      end

      private

      def self.normalize_dn_part(part)
        cleaned = part.strip

        if cleaned.ends_with?('\\')
          # If it ends with an escape character that is not followed by a
          # character to be escaped, then this part may be malformed. But let's
          # not worry too much about it, and just return it unmodified.
          #
          # Why? Because the reason we clean DNs is to make our simplistic
          # string comparisons work better, even though there are all kinds of
          # ways that equivalent DNs can vary as strings. If we run into a
          # strange DN, we should just try to work with it.
          #
          # See https://www.ldap.com/ldap-dns-and-rdns for more.
          return part unless part.ends_with?(' ')

          # Ends with an escaped space (which is valid).
          cleaned = cleaned + ' '
        end

        # Get rid of blanks. This can happen if a split character is followed by
        # whitespace and then another split character.
        #
        # E.g. this DN: 'uid=john+telephoneNumber= +1 555-555-5555'
        #
        # Should be returned as: 'uid=john+telephoneNumber=+1 555-555-5555'
        cleaned = '' if cleaned.blank?

        cleaned
      end

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

        entry.public_send(selected_attr) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
