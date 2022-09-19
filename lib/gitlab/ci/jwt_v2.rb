# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2 < Jwt
      private

      def reserved_claims
        super.merge(
          iss: Settings.gitlab.base_url,
          sub: "project_path:#{project.full_path}:ref_type:#{ref_type}:ref:#{source_ref}",
          aud: Settings.gitlab.base_url
        )
      end
    end
  end
end
