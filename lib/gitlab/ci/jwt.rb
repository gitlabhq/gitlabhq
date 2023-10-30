# frozen_string_literal: true

module Gitlab
  module Ci
    class Jwt
      NOT_BEFORE_TIME = 5
      DEFAULT_EXPIRE_TIME = 60 * 5

      NoSigningKeyError = Class.new(StandardError)

      def self.for_build(build)
        self.new(build, ttl: build.metadata_timeout).encoded
      end

      def initialize(build, ttl:)
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

      attr_reader :build, :ttl

      delegate :project, :user, :pipeline, :runner, to: :build
      delegate :source_ref, :source_ref_path, to: :pipeline
      delegate :public_key, to: :key
      delegate :namespace, to: :project

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
        fields = {
          namespace_id: namespace.id.to_s,
          namespace_path: namespace.full_path,
          project_id: project.id.to_s,
          project_path: project.full_path,
          user_id: user&.id.to_s,
          user_login: user&.username,
          user_email: user&.email,
          pipeline_id: pipeline.id.to_s,
          pipeline_source: pipeline.source.to_s,
          job_id: build.id.to_s,
          ref: source_ref,
          ref_type: ref_type,
          ref_path: source_ref_path,
          ref_protected: build.protected.to_s
        }

        if environment.present?
          fields.merge!(
            environment: environment.name,
            environment_protected: environment_protected?.to_s,
            deployment_tier: build.environment_tier
          )
        end

        fields
      end

      def key
        @key ||= begin
          key_data = Gitlab::CurrentSettings.ci_jwt_signing_key

          raise NoSigningKeyError unless key_data

          OpenSSL::PKey::RSA.new(key_data)
        end
      end

      def kid
        public_key.to_jwk[:kid]
      end

      def ref_type
        ::Ci::BuildRunnerPresenter.new(build).ref_type
      end

      def environment
        build.persisted_environment
      end

      def environment_protected?
        false # Overridden in EE
      end
    end
  end
end

Gitlab::Ci::Jwt.prepend_mod_with('Gitlab::Ci::Jwt')
