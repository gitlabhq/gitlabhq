# frozen_string_literal: true

module Gitlab
  module Checks
    module Integrations
      class BeyondIdentityCheck < ::Gitlab::Checks::BaseBulkChecker
        LOG_MESSAGE = 'Starting BeyondIdentity scan...'
        COMMIT_HAS_NO_SIGNATURE_ERROR = 'Commit is not signed with a GPG signature'
        INTEGRATION_VERIFICATION_PERIOD = 1.day

        def initialize(integration_check)
          @changes_access = integration_check.changes_access
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
              signature = commit.signature
              unless signature.verified?
                raise ::Gitlab::GitAccess::ForbiddenError, "Signature of the commit #{commit.sha} is not verified"
              end

              key = signature.gpg_key
              unless key
                gpg_commit = commit.gpg_commit
                gpg_commit.update_signature!(signature)

                key = gpg_commit.signature.gpg_key
              end

              unless reverified_with_integration?(key)
                raise ::Gitlab::GitAccess::ForbiddenError, "GPG Key used to sign commit #{commit.sha} is not verified"
              end
            end
          end
        end

        private

        def skip_validation?
          return true unless integration&.activated?
          return true if updated_from_web?
          return true if integration.exclude_service_accounts? && user_access.user.service_account?

          false
        end

        def reverified_with_integration?(key)
          strong_memoize_with(:verified_by_integration, key) do
            break false unless key.present?

            gpg_key = key.is_a?(GpgKeySubkey) ? key.gpg_key : key

            break gpg_key.externally_verified? unless require_reverification?(gpg_key)

            verified_externally?(gpg_key).tap do |verified_externally|
              key.update!(externally_verified: verified_externally, externally_verified_at: Time.current)
            end
          end
        end

        def verified_externally?(key)
          integration.execute({ key_id: key.primary_keyid, committer_email: key.user.email })

          true
        rescue ::Gitlab::BeyondIdentity::Client::ApiError => _
          false
        end

        def require_reverification?(key)
          return true unless key.externally_verified_at.present?

          key.externally_verified_at <= INTEGRATION_VERIFICATION_PERIOD.ago
        end

        def integration
          project.beyond_identity_integration || ::Integrations::BeyondIdentity.for_instance.first
        end
        strong_memoize_attr :integration
      end
    end
  end
end
