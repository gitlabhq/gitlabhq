# frozen_string_literal: true

module Gitlab
  module Ci
    class OidcBurnedPathError < StandardError
      MESSAGE = <<~MSG
        ID token issuance is disabled for this project because a project
        path in the `sub` claim was previously held by a different project.

        To restore ID token issuance, set `ci_id_token_sub_claim_components`
        for this project to start with the ID component that matches the
        path component (`project_id`, `job_project_id`, or `source_project_id`).
        See: https://docs.gitlab.com/ci/secrets/id_token_authentication/#error-id-token-issuance-is-disabled

        If the path was legitimately reused, ask an instance administrator
        to review.
      MSG

      def initialize(message = MESSAGE)
        super
      end
    end
  end
end
