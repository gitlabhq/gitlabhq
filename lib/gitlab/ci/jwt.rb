# frozen_string_literal: true

module Gitlab
  module Ci
    class Jwt < JwtBase
      NOT_BEFORE_TIME = 5
      DEFAULT_EXPIRE_TIME = 60 * 5

      def self.for_build(build)
        self.new(build, ttl: build.metadata_timeout).encoded
      end

      def initialize(build, ttl:)
        super()

        @build = build
        @ttl = ttl
      end

      private

      attr_reader :build, :ttl

      delegate :project, :user, :pipeline, :runner, to: :build
      delegate :source_ref, :source_ref_path, to: :pipeline

      def default_payload
        now = Time.now.to_i

        super.merge(
          jti: SecureRandom.uuid,
          iss: Settings.gitlab.host,
          iat: now,
          nbf: now - NOT_BEFORE_TIME,
          exp: now + (ttl || DEFAULT_EXPIRE_TIME),
          sub: "job_#{build.id}"
        )
      end

      def predefined_claims
        project_claims.merge(ci_claims)
      end

      def project_claims
        ::JSONWebToken::ProjectTokenClaims
         .new(project: project, user: user)
         .generate
      end

      def ci_claims
        fields = {
          pipeline_id: pipeline.id.to_s,
          pipeline_source: pipeline.source.to_s,
          job_id: build.id.to_s,
          ref: source_ref,
          ref_type: ref_type,
          ref_path: source_ref_path,
          ref_protected: build.protected.to_s
        }

        if Feature.enabled?(:ci_jwt_groups_direct, project, type: :ops) ||
            Feature.enabled?(:ci_jwt_groups_direct, project.root_namespace, type: :ops)
          direct_groups = user&.first_group_paths
          fields[:groups_direct] = direct_groups if direct_groups
        end

        if environment.present?
          fields.merge!(
            environment: environment.name,
            environment_protected: environment_protected?.to_s,
            deployment_tier: build.environment_tier,
            environment_action: build.environment_action
          )
        end

        fields
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
