# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2 < Jwt
      DEFAULT_AUD = Settings.gitlab.base_url

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
        super.merge(
          iss: Settings.gitlab.base_url,
          sub: "project_path:#{project.full_path}:ref_type:#{ref_type}:ref:#{source_ref}",
          aud: aud
        )
      end
    end
  end
end
