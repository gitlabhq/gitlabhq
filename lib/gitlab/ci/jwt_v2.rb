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
        super.merge(
          runner_id: runner&.id,
          runner_environment: runner_environment,
          sha: build.pipeline.sha
        )
      end

      def runner_environment
        return unless runner

        runner.gitlab_hosted? ? GITLAB_HOSTED_RUNNER : SELF_HOSTED_RUNNER
      end
    end
  end
end
