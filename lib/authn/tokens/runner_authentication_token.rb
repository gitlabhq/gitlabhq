# frozen_string_literal:true

module Authn
  module Tokens
    class RunnerAuthenticationToken
      LEGACY_RUNNER_PARTITION_PREFIXES = %w[t1_ t2_ t3_].freeze

      def self.prefix?(plaintext)
        prefixes = [
          # Introduced @ 2025-10-25 by https://gitlab.com/gitlab-org/gitlab/-/commit/8e04578f1f26790d19d822308ff712adfac72567
          ::Ci::Runner.created_runner_prefix,
          # NOTE: The constant name is confusing. This is a real runner auth token prefix.
          # Introduced @ 2025-03-28 by https://gitlab.com/gitlab-org/gitlab/-/commit/1862822c55cdc49491ff5840656df76dab453def
          ::Ci::Runner::REGISTRATION_RUNNER_TOKEN_PREFIX,
          # Introduced @ 2024-10-04 by https://gitlab.com/gitlab-org/gitlab/-/commit/92df90f977a2e6f15fdc41d3c185f21dd4f78377
          *LEGACY_RUNNER_PARTITION_PREFIXES,
          # Introduced @ 2023-01-30 by https://gitlab.com/gitlab-org/gitlab/-/commit/bae42e666bb35fb618d2a125311fd1a28fc6a849
          ::Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX
        ]

        plaintext.start_with?(*prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        return unless self.class.prefix?(plaintext)

        @revocable = ::Ci::Runner.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Ci::Runner
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        service = ::Ci::Runners::ResetAuthenticationTokenService.new(runner: revocable, current_user: current_user)
        service.execute
      end
    end
  end
end
