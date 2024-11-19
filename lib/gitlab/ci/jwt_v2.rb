# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2 < Jwt
      include Gitlab::Utils::StrongMemoize

      GITLAB_HOSTED_RUNNER = 'gitlab-hosted'
      SELF_HOSTED_RUNNER = 'self-hosted'

      def self.for_build(
        build, aud:, sub_components: [:project_path, :ref_type,
          :ref], target_audience: nil)
        new(build, ttl: build.metadata_timeout, aud: aud, sub_components: sub_components,
          target_audience: target_audience).encoded
      end

      def initialize(build, ttl:, aud:, sub_components:, target_audience:)
        super(build, ttl: ttl)

        @aud = aud
        @sub = sub_components.select { |claim_name| custom_claims[claim_name] }
          .flat_map { |claim_name| [claim_name, custom_claims[claim_name]] }.join(':')
        @target_audience = target_audience
      end

      private

      attr_reader :aud, :sub, :target_audience

      def default_payload
        super.merge({
          iss: Gitlab.config.gitlab.url,
          sub: sub,
          aud: aud,
          target_audience: target_audience
        }.compact)
      end

      def custom_claims
        { project_path: project.full_path,
          ref_type: ref_type,
          ref: source_ref }
      end

      def predefined_claims
        additional_custom_claims = {
          runner_id: runner&.id,
          runner_environment: runner_environment,
          sha: pipeline.sha,
          project_visibility: Gitlab::VisibilityLevel.string_level(project.visibility_level),
          user_identities: user_identities,
          target_audience: target_audience
        }.compact

        mapper = ClaimMapper.new(project_config, pipeline)

        super.merge(additional_custom_claims).merge(mapper.to_h)
      end

      def user_identities
        return unless user&.pass_user_identities_to_ci_jwt

        user.identities.map do |identity|
          {
            provider: identity.provider.to_s,
            extern_uid: identity.extern_uid.to_s
          }
        end
      end

      def project_config
        Gitlab::Ci::ProjectConfig.new(
          project: project,
          sha: pipeline.sha,
          pipeline_source: pipeline.source&.to_sym,
          pipeline_source_bridge: pipeline.source_bridge
        )
      end
      strong_memoize_attr(:project_config)

      def runner_environment
        return unless runner

        runner.gitlab_hosted? ? GITLAB_HOSTED_RUNNER : SELF_HOSTED_RUNNER
      end
    end
  end
end
