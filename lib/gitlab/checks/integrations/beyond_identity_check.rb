# frozen_string_literal: true

module Gitlab
  module Checks
    module Integrations
      class BeyondIdentityCheck < ::Gitlab::Checks::BaseBulkChecker
        LOG_MESSAGE = 'Starting BeyondIdentity scan...'
        COMMIT_HAS_NO_SIGNATURE_ERROR = 'Commit is not signed by a GPG signature'

        def initialize(integration_check)
          @changes_access = integration_check.changes_access
          @integration = ::Integrations::BeyondIdentity.for_instance.first
        end

        def validate!
          return unless integration_activated?
          return if updated_from_web?

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

        def integration_activated?
          integration.present? && integration.activated?
        end
      end
    end
  end
end
