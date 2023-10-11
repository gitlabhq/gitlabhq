# frozen_string_literal: true

# Class to parse and transform the info provided by omniauth
#
module Gitlab
  module Auth
    module Ldap
      class AuthHash < Gitlab::Auth::OAuth::AuthHash
        extend ::Gitlab::Utils::Override

        def uid
          @uid ||= Gitlab::Auth::Ldap::Person.normalize_dn(super)
        end

        def username
          super.tap do |username|
            username.downcase! if ldap_config.lowercase_usernames
          end
        end

        private

        def get_info(key)
          attributes = ldap_config.attributes[key.to_s]
          return super unless attributes

          attributes = Array(attributes)

          value = nil
          attributes.each do |attribute|
            value = get_raw(attribute)
            value = value.first if value
            break if value.present?
          end

          return super unless value

          Gitlab::Utils.force_utf8(value)
          value
        end

        def get_raw(key)
          auth_hash.extra[:raw_info][key] if auth_hash.extra
        end

        def ldap_config
          @ldap_config ||= Gitlab::Auth::Ldap::Config.new(self.provider)
        end

        # Overrding this method as LDAP allows email as the username !
        override :get_username
        def get_username
          username_claims.map { |claim| get_from_auth_hash_or_info(claim) }.find(&:presence)
        end
      end
    end
  end
end
