module Gitlab
  module Auth
    module Saml
      class AuthHash < Gitlab::Auth::OAuth::AuthHash
        def groups
          Array.wrap(get_raw(Gitlab::Auth::Saml::Config.groups))
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
end
