# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class AuthHash < Gitlab::Auth::OAuth::AuthHash
        def groups
          Array.wrap(get_raw(Gitlab::Auth::Saml::Config.new(auth_hash.provider).groups))
        end

        def azure_group_overage_claim?
          get_raw('http://schemas.microsoft.com/claims/groups.link').present?
        end

        def authn_context
          response_object = auth_hash.extra[:response_object]
          return unless response_object.is_a?(OneLogin::RubySaml::Response)

          response_object.authn_context_class_ref
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
