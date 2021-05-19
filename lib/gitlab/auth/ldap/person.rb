# frozen_string_literal: true

module Gitlab
  module Auth
    module Ldap
      class Person
        # Active Directory-specific LDAP filter that checks if bit 2 of the
        # userAccountControl attribute is set.
        # Source: http://ctogonewild.com/2009/09/03/bitmask-searches-in-ldap/
        AD_USER_DISABLED = Net::LDAP::Filter.ex("userAccountControl:1.2.840.113556.1.4.803", "2")

        InvalidEntryError = Class.new(StandardError)

        attr_accessor :provider

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
            'dn',
            config.uid,
            *config.attributes['name'],
            *config.attributes['email'],
            *config.attributes['username']
          ].compact.uniq.reject(&:blank?)
        end

        def self.normalize_dn(dn)
          ::Gitlab::Auth::Ldap::DN.new(dn).to_normalized_s
        rescue ::Gitlab::Auth::Ldap::DN::FormatError => e
          Gitlab::AppLogger.info("Returning original DN \"#{dn}\" due to error during normalization attempt: #{e.message}")

          dn
        end

        # Returns the UID in a normalized form.
        #
        # 1. Excess spaces are stripped
        # 2. The string is downcased (for case-insensitivity)
        def self.normalize_uid(uid)
          ::Gitlab::Auth::Ldap::DN.normalize_value(uid)
        rescue ::Gitlab::Auth::Ldap::DN::FormatError => e
          Gitlab::AppLogger.info("Returning original UID \"#{uid}\" due to error during normalization attempt: #{e.message}")

          uid
        end

        def initialize(entry, provider)
          Gitlab::AppLogger.debug "Instantiating #{self.class.name} with LDIF:\n#{entry.to_ldif}"
          @entry = entry
          @provider = provider
        end

        def name
          attribute_value(:name)&.first
        end

        def uid
          entry.public_send(config.uid).first # rubocop:disable GitlabSecurity/PublicSend
        end

        def username
          username = attribute_value(:username)

          # Depending on the attribute, multiple values may
          # be returned. We need only one for username.
          # Ex. `uid` returns only one value but `mail` may
          # return an array of multiple email addresses.
          [username].flatten.first.tap do |username|
            username.downcase! if config.lowercase_usernames
          end
        end

        def email
          attribute_value(:email)
        end

        def dn
          self.class.normalize_dn(entry.dn)
        end

        private

        attr_reader :entry

        def config
          @config ||= Gitlab::Auth::Ldap::Config.new(provider)
        end

        # Using the LDAP attributes configuration, find and return the first
        # attribute with a value. For example, by default, when given 'email',
        # this method looks for 'mail', 'email' and 'userPrincipalName' and
        # returns the first with a value.
        def attribute_value(attribute)
          attributes = Array(config.attributes[attribute.to_s])
          selected_attr = attributes.find { |attr| entry.respond_to?(attr) }

          return unless selected_attr

          entry.public_send(selected_attr) # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end

Gitlab::Auth::Ldap::Person.prepend_mod_with('Gitlab::Auth::Ldap::Person')
