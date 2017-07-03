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
          dn_components
            .reverse
            .take_while { |rdn| rdn[:name].casecmp('DC').zero? } # Domain Component
          .map { |rdn| rdn[:value] }
            .reverse
            .join('.')
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
