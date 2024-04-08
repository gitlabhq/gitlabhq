# frozen_string_literal: true

module Gitlab
  module Checks
    module Integrations
      class BeyondIdentityCheck < ::Gitlab::Checks::BaseBulkChecker
        LOG_MESSAGE = 'Starting BeyondIdentity scan...'
        COMMIT_HAS_NO_SIGNATURE_ERROR = 'Commit is not signed with a GPG signature'

        def initialize(integration_check)
          @changes_access = integration_check.changes_access
          @integration = ::Integrations::BeyondIdentity.for_instance.first
        end

        def validate!
          return if skip_validation?

          logger.log_timed(LOG_MESSAGE) do
            commits = changes_access.commits

            unless commits.all? { |commit| commit.has_signature? && commit.signature_type == :PGP }
              raise ::Gitlab::GitAccess::ForbiddenError, COMMIT_HAS_NO_SIGNATURE_ERROR
            end

            # Initialize the signed commit first in order to lazily load the signatures
            # from Gitaly in a single batch request
            commits.each(&:gpg_commit)

            commits.each do |commit|
              unless commit.signature.verified?
                raise ::Gitlab::GitAccess::ForbiddenError, "Signature of the commit #{commit.sha} is not verified"
              end
            end
          end
        end

        private

        attr_reader :integration

        def skip_validation?
          return true unless integration&.activated?
          return true if updated_from_web?
          return true if integration.exclude_service_accounts? && user_access.user.service_account?

          false
        end
      end
    end
  end
end
