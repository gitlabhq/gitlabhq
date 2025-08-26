# frozen_string_literal: true

module Gitlab
  module DoorkeeperSecretStoring
    module Token
      class UniqueApplicationToken
        # Acronym for 'GitLab OAuth Application Secret'
        OAUTH_APPLICATION_SECRET_PREFIX_FORMAT = "gloas-%{token}"

        # Maintains compatibility with ::Doorkeeper::OAuth::Helpers::UniqueToken
        # Returns a secure random token, prefixed with a GitLab identifier.
        def self.generate(*)
          format(prefix_for_oauth_application_secret, token: SecureRandom.hex(32))
        end

        def self.prefix_for_oauth_application_secret
          ::Authn::TokenField::PrefixHelper.prepend_instance_prefix(OAUTH_APPLICATION_SECRET_PREFIX_FORMAT)
        end
      end
    end
  end
end
