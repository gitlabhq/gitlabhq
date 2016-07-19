module Gitlab
  module Saml
    class AuthHash < Gitlab::OAuth::AuthHash
      def groups
        get_raw(Gitlab::Saml::Config.groups)
      end

      private

      def get_raw(key)
        # Needs to call `all` because of https://git.io/vVo4u
        # otherwise just the first value is returned
        auth_hash.extra[:raw_info].all[key]
      end
    end
  end
end
