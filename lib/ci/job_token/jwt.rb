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
      include Gitlab::Utils::StrongMemoize

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

          payload = build_payload(job)

          ::Authn::Tokens::Jwt.rsa_encode(
            subject: job,
            signing_key: key,
            expire_time: expire_time(job),
            token_prefix: token_prefix,
            custom_payload: payload)
        end

        def decode(token)
          return unless key

          actual_token_prefix = token.starts_with?(::Ci::Build::TOKEN_PREFIX) ? ::Ci::Build::TOKEN_PREFIX : token_prefix

          jwt = ::Authn::Tokens::Jwt.rsa_decode(
            token: token,
            signing_public_key: key.public_key,
            subject_type: subject_type,
            token_prefix: actual_token_prefix)
          new(jwt) if jwt
        end

        def build_payload(job)
          base_payload = { scoped_user_id: job.scoped_user&.id }.compact_blank
          base_payload.merge(routable_payload(job))
        end

        # Creating routing information for routable tokens https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/routable_tokens/
        def routable_payload(job)
          {
            c: Gitlab.config.cell.id,
            o: job.project.organization_id,
            u: job.user_id,
            p: job.project_id,
            g: job.project.group&.id
          }.compact_blank.transform_values { |id| id.to_s(36) }
        end

        def token_prefix
          ::Authn::TokenField::PrefixHelper.prepend_instance_prefix(::Ci::Build::TOKEN_PREFIX)
        end

        def subject_type
          ::Ci::Build
        end

        def expire_time(job)
          ttl = [::JSONWebToken::Token::DEFAULT_EXPIRE_TIME, job.timeout_value.to_i].max
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

      def initialize(jwt)
        raise ArgumentError, 'argument is not Authn::Tokens::Jwt' unless jwt.is_a?(::Authn::Tokens::Jwt)

        @jwt = jwt
      end

      def job
        @jwt.subject
      end

      def scoped_user
        scoped_user_id = @jwt.payload['scoped_user_id']
        User.find_by_id(scoped_user_id) if scoped_user_id
      end
      strong_memoize_attr :scoped_user

      def cell_id
        decode(@jwt.payload['c'])
      end

      def organization_id
        decode(@jwt.payload['o'])
      end

      def project_id
        decode(@jwt.payload['p'])
      end

      def user_id
        decode(@jwt.payload['u'])
      end

      def group_id
        decode(@jwt.payload['g'])
      end

      private

      def decode(encoded_value)
        encoded_value&.to_i(36)
      end
    end
  end
end
