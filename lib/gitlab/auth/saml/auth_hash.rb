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
          return if response_object.blank?

          document = response_object.decrypted_document
          document ||= response_object.document
          return if document.blank?

          extract_authn_context(document)
        end

        private

        def get_raw(key)
          # Needs to call `all` because of https://git.io/vVo4u
          # otherwise just the first value is returned
          auth_hash.extra[:raw_info].all[key]
        end

        def extract_authn_context(document)
          REXML::XPath.first(document, "//*[name()='saml:AuthnStatement' or name()='saml2:AuthnStatement' or name()='AuthnStatement']/*[name()='saml:AuthnContext' or name()='saml2:AuthnContext' or name()='AuthnContext']/*[name()='saml:AuthnContextClassRef' or name()='saml2:AuthnContextClassRef' or name()='AuthnContextClassRef']/text()").to_s
        end
      end
    end
  end
end
