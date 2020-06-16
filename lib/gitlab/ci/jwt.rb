# frozen_string_literal: true

module Gitlab
  module Ci
    class Jwt
      NOT_BEFORE_TIME = 5
      DEFAULT_EXPIRE_TIME = 60 * 5

      def self.for_build(build)
        self.new(build, ttl: build.metadata_timeout).encoded
      end

      def initialize(build, ttl: nil)
        @build = build
        @ttl = ttl
      end

      def payload
        custom_claims.merge(reserved_claims)
      end

      def encoded
        headers = { kid: kid, typ: 'JWT' }

        JWT.encode(payload, key, 'RS256', headers)
      end

      private

      attr_reader :build, :ttl, :key_data

      def reserved_claims
        now = Time.now.to_i

        {
          jti: SecureRandom.uuid,
          iss: Settings.gitlab.host,
          iat: now,
          nbf: now - NOT_BEFORE_TIME,
          exp: now + (ttl || DEFAULT_EXPIRE_TIME),
          sub: "job_#{build.id}"
        }
      end

      def custom_claims
        {
          namespace_id: namespace.id.to_s,
          namespace_path: namespace.full_path,
          project_id: project.id.to_s,
          project_path: project.full_path,
          user_id: user&.id.to_s,
          user_login: user&.username,
          user_email: user&.email,
          pipeline_id: build.pipeline.id.to_s,
          job_id: build.id.to_s,
          ref: source_ref,
          ref_type: ref_type,
          ref_protected: build.protected.to_s
        }
      end

      def key
        @key ||= OpenSSL::PKey::RSA.new(Rails.application.secrets.openid_connect_signing_key)
      end

      def public_key
        key.public_key
      end

      def kid
        public_key.to_jwk[:kid]
      end

      def project
        build.project
      end

      def namespace
        project.namespace
      end

      def user
        build.user
      end

      def source_ref
        build.pipeline.source_ref
      end

      def ref_type
        ::Ci::BuildRunnerPresenter.new(build).ref_type
      end
    end
  end
end
