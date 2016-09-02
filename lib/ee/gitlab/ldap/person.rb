module EE
  module Gitlab
    module LDAP
      module Person
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
      end
    end
  end
end
