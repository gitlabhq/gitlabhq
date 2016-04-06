module Gitlab
  module Saml
    class AuthHash < Gitlab::OAuth::AuthHash

      def groups
        get_raw(Gitlab::Saml::Config.groups)
      end

      private

      def get_raw(key)
        # Needs to call `all` because of https://github.com/onelogin/ruby-saml/blob/master/lib/onelogin/ruby-saml/attributes.rb#L78
        # otherwise just the first value is returned
        auth_hash.extra[:raw_info].all[key]
      end

    end
  end
end
