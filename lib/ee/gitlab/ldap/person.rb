require 'net/ldap/dn'

module EE
  module Gitlab
    module LDAP
      module Person
        extend ActiveSupport::Concern

        class_methods do
          def find_by_email(email, adapter)
            email_attributes = Array(adapter.config.attributes['email'])

            email_attributes.each do |possible_attribute|
              found_user = adapter.user(possible_attribute, email)
              return found_user if found_user
            end

            nil
          end

          def find_by_kerberos_principal(principal, adapter)
            uid, domain = principal.split('@', 2)
            return nil unless uid && domain

            # In multi-forest setups, there may be several users with matching
            # uids but differing DNs, so skip adapters configured to connect to
            # non-matching domains
            return unless domain.casecmp(domain_from_dn(adapter.config.base)) == 0

            find_by_uid(uid, adapter)
          end

          # Extracts the rightmost unbroken set of domain components from an
          # LDAP DN and constructs a domain name from them
          def domain_from_dn(dn)
            dn_components = []
            Net::LDAP::DN.new(dn).each_pair { |name, value| dn_components << { name: name, value: value } }
            dn_components
              .reverse
              .take_while { |rdn| rdn[:name].casecmp('DC').zero? } # Domain Component
              .map { |rdn| rdn[:value] }
              .reverse
              .join('.')
          end
        end

        def ssh_keys
          if config.sync_ssh_keys? && entry.respond_to?(config.sync_ssh_keys)
            entry[config.sync_ssh_keys.to_sym]
              .map { |key| key[/(ssh|ecdsa)-[^ ]+ [^\s]+/] }
              .compact
          else
            []
          end
        end

        # We assume that the Kerberos username matches the configured uid
        # attribute in LDAP. For Active Directory, this is `sAMAccountName`
        def kerberos_principal
          return nil unless uid

          uid + '@' + self.class.domain_from_dn(dn).upcase
        end

        def memberof
          return [] unless entry.attribute_names.include?(:memberof)

          entry.memberof
        end

        def group_cns
          memberof.map { |memberof_value| cn_from_memberof(memberof_value) }
        end

        def cn_from_memberof(memberof)
          # Only get the first CN value of the string, that's the one that contains
          # the group name
          memberof.match(/(?:cn=([\w\s]+))/i)&.captures&.first
        end
      end
    end
  end
end
