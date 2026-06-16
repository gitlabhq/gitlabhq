# frozen_string_literal: true

module Gitlab
  module Ci
    class OidcBurnedPathError < StandardError
      MESSAGE = <<~MSG
        CI ID token issuance is disabled for this project because the project
        path was previously held by a different project.

        To restore CI ID token issuance, set `id_token_sub_claim_components`
        for this project to use `project_id` as the first element
        (for example, ["project_id", "ref_type", "ref"]).
        See: https://docs.gitlab.com/ci/cloud_services/#configurable-oidc-claims

        If the path was legitimately reused, ask an instance administrator
        to review.
      MSG

      def initialize(message = MESSAGE)
        super
      end
    end
  end
end
