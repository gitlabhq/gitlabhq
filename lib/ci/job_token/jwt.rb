# frozen_string_literal: true

# This class handles JSON Web Token (JWT) operations for CI job tokens.
#
# This class provides methods to encode and decode JWTs specifically for CI jobs.
# It uses RSA encryption for secure token generation and verification.
#
# Key features:
# - Encodes JWTs for CI::Build objects
# - Decodes and verifies JWTs
#
module Ci
  module JobToken
    class Jwt
      # After finishing, jobs need to be able to POST their final state to the `jobs` API endpoint,
      # for example to update their status or the final trace.
      # A leeway of 5 minutes ensures a job is able to do that after they have timed out.
      LEEWAY = 5.minutes

      class << self
        include Gitlab::Utils::StrongMemoize

        def encode(job)
          return unless job.is_a?(subject_type)
          return unless job.persisted?
          return unless key

          ::Authn::Tokens::Jwt.rsa_encode(
            subject: job,
            signing_key: key,
            expire_time: expire_time(job),
            token_prefix: token_prefix)
        end

        def decode(token)
          return unless key

          ::Authn::Tokens::Jwt.rsa_decode(
            token: token,
            signing_public_key: key.public_key,
            subject_type: subject_type,
            token_prefix: token_prefix)
        end

        def token_prefix
          ::Ci::Build::TOKEN_PREFIX
        end

        def subject_type
          ::Ci::Build
        end

        def expire_time(job)
          ttl = [::JSONWebToken::Token::DEFAULT_EXPIRE_TIME, job.metadata_timeout.to_i].max
          Time.current + ttl + LEEWAY
        end

        def key
          signing_key = Gitlab::CurrentSettings.ci_job_token_signing_key
          raise 'CI job token signing key is not set' unless signing_key

          OpenSSL::PKey::RSA.new(signing_key.to_s)
        rescue OpenSSL::PKey::RSAError => error
          Gitlab::ErrorTracking.track_exception(error)
          nil
        end
      end
    end
  end
end
