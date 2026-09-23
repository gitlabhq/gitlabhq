# frozen_string_literal: true

module Authz
  module Organizations
    module OwnerRoleSync
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker

        feature_category :system_access
        data_consistency :sticky
        urgency :low
        idempotent!
        deduplicate :until_executed
        worker_has_external_dependencies!
        # Caps concurrent load on the IAM data access service, since a bulk
        # operation could otherwise enqueue a large burst of these at once.
        concurrency_limit -> { 50 }
      end

      # :unauthenticated is included since the token is minted fresh per
      # call, so a failure there is more likely transient than a broken token.
      RETRYABLE_REASONS = %i[unavailable timeout unknown unauthenticated].freeze

      # Raised only for reasons in RETRYABLE_REASONS, so Sidekiq's default
      # exception-triggered retry engages. Subclassing RetryError only
      # suppresses Sidekiq's own auto-report for the retry; the gRPC client
      # (DataAccessClient#request_error) already reports every failure
      # unconditionally.
      RequestError = Class.new(Gitlab::SidekiqMiddleware::RetryError)

      # Not retried: a stale/missing actor won't resolve itself, so raising
      # RequestError here would just retry into the same dead end.
      UnauthorizedRevokeError = Class.new(StandardError)

      # Single enqueue gate for every owner change: IAM must be configured and
      # this edition must be able to mint the token the write is authorized with.
      def self.enabled?
        ::Authn::IamDataAccessService.configured? && ::Authn::TokenExchange::TokenIssuer.available?
      end

      private

      # [organization, user] once both resolve, else nil after logging the
      # skip. Shared by both workers' perform.
      def organization_and_user(organization_id, user_id)
        organization = organization_from(organization_id)
        user = user_from(user_id)

        return [organization, user] if organization && user

        log_skip(reason: 'organization or user not found', organization_id: organization_id, user_id: user_id)
        nil
      end

      def organization_from(organization_id)
        ::Organizations::Organization.find_by_id(organization_id)
      end

      def user_from(user_id)
        ::User.find_by_id(user_id)
      end

      # Re-checks ground truth rather than trusting the enqueue-time state,
      # since Sidekiq doesn't guarantee ordering across retries.
      def currently_owner?(organization, user)
        user.owns_organization?(organization)
      end

      # Re-verifies actor_id is still a current owner, since it can go
      # stale between enqueue and this async execution. Interim tech debt:
      # goes away once IAM writes move to the IAM outbox approach.
      def acting_owner_for(organization, actor_id)
        return unless actor_id

        actor = user_from(actor_id)
        actor if actor && currently_owner?(organization, actor)
      end

      def iam_client
        ::Authn::IamService::UpdateRelationshipsClient.new
      end

      # This token is only ever presented back to iam-data-access, so that's
      # the only audience it needs.
      def token_for(organization, user)
        ::Authn::TokenExchange::TokenIssuer.new(
          audiences: [::Authn::TokenExchange::TokenIssuer::DATA_ACCESS_AUDIENCE],
          user: user,
          organization: organization
        ).token
      end

      def organization_admin_role_id
        ::Authz::Organizations::Roles.organization_admin_uuid
      end

      def retryable_reason?(reason)
        RETRYABLE_REASONS.include?(reason)
      end

      def log_skip(reason:, organization_id:, user_id:)
        Gitlab::AppLogger.info(build_structured_payload_labkit(
          message: "Organization admin role sync skipped: #{reason}",
          Labkit::Fields::GL_ORGANIZATION_ID => organization_id,
          Labkit::Fields::GL_USER_ID => user_id
        ))
      end

      def log_error(message, organization_id:, user_id:)
        Gitlab::AppLogger.error(build_structured_payload_labkit(
          message: "Organization admin role sync failed: #{message}",
          Labkit::Fields::GL_ORGANIZATION_ID => organization_id,
          Labkit::Fields::GL_USER_ID => user_id
        ))
      end
    end
  end
end
