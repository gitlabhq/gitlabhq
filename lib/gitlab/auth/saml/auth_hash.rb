# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class AuthHash < Gitlab::Auth::OAuth::AuthHash
        extend ::Gitlab::Utils::Override

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

        # SAML administrators map the standard location field of the OmniAuth
        # info hash schema through attribute_statements. The fallback is scoped
        # to SAML because strategies of other providers populate the field with
        # unrelated data, for example a time zone or a synthetic pattern
        # string. See https://gitlab.com/gitlab-org/gitlab/-/issues/496518.
        override :location
        def location
          super.presence || get_info(:location)
        end

        override :has_attribute?
        def has_attribute?(attribute)
          return true if attribute == :location && get_info(:location).present?

          super
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
