# Class to parse and transform the info provided by omniauth
#
module Gitlab
  module LDAP
    class AuthHash < Gitlab::OAuth::AuthHash
      private

      def get_info(key)
        raw_key = ldap_config.attributes[key]
        return super unless raw_key

        value =
          case raw_key
          when String
            get_raw(raw_key)
          when Array
            raw_key.inject(nil) { |value, key| value || get_raw(key).presence }
          else
            nil
          end
        
        return super unless value

        Gitlab::Utils.force_utf8(value)
        value
      end

      def get_raw(key)
        auth_hash.extra[:raw_info][key]
      end

      def ldap_config
        @ldap_config ||= Gitlab::LDAP::Config.new(self.provider)
      end
    end
  end
end
