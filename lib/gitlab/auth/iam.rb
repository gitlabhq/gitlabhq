# frozen_string_literal: true

module Gitlab
  module Auth
    module Iam
      Error = Class.new(Gitlab::Auth::AuthenticationError)

      ConfigurationError = Class.new(Error)
      ServiceUnavailableError = Class.new(Error)

      class << self
        include Gitlab::Utils::StrongMemoize

        def service_url
          Gitlab.config.authn.iam_service.url
        end
        strong_memoize_attr :service_url

        def issuer
          # Issuer is the same as the service URL
          Gitlab.config.authn.iam_service.url
        end
        strong_memoize_attr :issuer

        def enabled?
          Gitlab.config.authn.iam_service.enabled
        end
      end
    end
  end
end
