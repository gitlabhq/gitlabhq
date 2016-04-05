module Gitlab
  module Saml
    class AuthHash < Gitlab::OAuth::AuthHash

      def groups
        get_raw(Gitlab::Saml::Config.groups)
      end

      private

      def get_raw(key)
        auth_hash.extra[:raw_info][key]
      end

    end
  end
end
