module Gitlab
  module Auth
    module Saml
      class AuthHash < Gitlab::Auth::OAuth::AuthHash
        def groups
          Array.wrap(get_raw(Gitlab::Auth::Saml::Config.groups))
        end

        def authn_context
          response_object = auth_hash.extra[:response_object]
          return nil if response_object.blank?

          document = response_object.decrypted_document
          document ||= response_object.document
          return nil if document.blank?

          extract_authn_context(document)
        end

        private

        def get_raw(key)
          # Needs to call `all` because of https://git.io/vVo4u
          # otherwise just the first value is returned
          auth_hash.extra[:raw_info].all[key]
        end

        def extract_authn_context(document)
          REXML::XPath.first(document, "//saml:AuthnStatement/saml:AuthnContext/saml:AuthnContextClassRef/text()").to_s
        end
      end
    end
  end
end
