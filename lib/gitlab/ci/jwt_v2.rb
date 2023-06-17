# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2 < Jwt
      DEFAULT_AUD = Settings.gitlab.base_url
      GITLAB_HOSTED_RUNNER = 'gitlab-hosted'
      SELF_HOSTED_RUNNER = 'self-hosted'

      def self.for_build(build, aud: DEFAULT_AUD)
        new(build, ttl: build.metadata_timeout, aud: aud).encoded
      end

      def initialize(build, ttl:, aud:)
        super(build, ttl: ttl)

        @aud = aud
      end

      private

      attr_reader :aud

      def reserved_claims
        super.merge({
          iss: Settings.gitlab.base_url,
          sub: "project_path:#{project.full_path}:ref_type:#{ref_type}:ref:#{source_ref}",
          aud: aud,
          user_identities: user_identities
        }.compact)
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

      def custom_claims
        additional_claims = {
          runner_id: runner&.id,
          runner_environment: runner_environment,
          sha: pipeline.sha
        }

        if Feature.enabled?(:ci_jwt_v2_ref_uri_claim, pipeline.project)
          additional_claims[:ci_config_ref_uri] = ci_config_ref_uri
        end

        super.merge(additional_claims)
      end

      def ci_config_ref_uri
        project_config = Gitlab::Ci::ProjectConfig.new(
          project: project,
          sha: pipeline.sha,
          pipeline_source: pipeline.source&.to_sym,
          pipeline_source_bridge: pipeline.source_bridge
        )

        return unless project_config&.source == :repository_source

        "#{project_config.url}@#{pipeline.source_ref_path}"

        # Errors are rescued to mitigate risk. This can be removed if no errors are observed.
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117923#note_1387660746 for context.
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, pipeline_id: pipeline.id)
        nil
      end

      def runner_environment
        return unless runner

        runner.gitlab_hosted? ? GITLAB_HOSTED_RUNNER : SELF_HOSTED_RUNNER
      end
    end
  end
end
