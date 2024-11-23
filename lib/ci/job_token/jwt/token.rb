# frozen_string_literal: true

module Ci
  module JobToken
    module Jwt
      module Token
        include Gitlab::Utils::StrongMemoize

        def expected_type
          ::Ci::Build
        end

        def key
          signing_key = Gitlab::CurrentSettings.ci_job_token_signing_key
          OpenSSL::PKey::RSA.new(signing_key.to_s)
        rescue OpenSSL::PKey::RSAError => error
          Gitlab::ErrorTracking.track_exception(error)
          nil
        end
        strong_memoize_attr :key

        def token_prefix
          ::Ci::Build::TOKEN_PREFIX
        end
      end
    end
  end
end
