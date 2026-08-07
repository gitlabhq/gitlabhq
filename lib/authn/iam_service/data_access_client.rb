# frozen_string_literal: true

module Authn
  module IamService
    # Shared base for the IAM Relationships API clients that talk to the IAM
    # data access service (Authn::IamDataAccessService): the write/delete path
    # (UpdateRelationshipsClient) and the read path (LookupRelationshipsClient).
    #
    # Holds the error contract, the bearer + service token metadata, and the
    # timeout common to both. Subclasses own their stub class and RPC methods.
    #
    # Callers present an AR-scoped bearer token minted by the Rails token
    # exchange (Authn::TokenExchange::TokenIssuer). IAM validates the token and
    # authorizes the caller server-side -- these clients do not perform
    # authorization.
    class DataAccessClient < BaseClient
      # Carries a machine-readable reason so callers can map the failure to a
      # user-facing message without parsing the message text. The message itself
      # stays diagnostic (it includes the raw gRPC status) for logs and Sentry.
      class RequestError < StandardError
        attr_reader :reason

        def initialize(message, reason: :unknown)
          @reason = reason
          super(message)
        end
      end

      # Allows headroom for bulk writes, which send up to the array argument
      # limit of tuples in a single all-or-nothing transaction. A read returns
      # one keyset page bounded by page_size, so it stays well within this.
      TIMEOUT_SECONDS = 15

      # Maps the gRPC statuses the IAM Relationships API returns to a
      # machine-readable reason for the caller to translate. Keyed by the
      # integer gRPC status code (GRPC::BadStatus#code); unlisted statuses fall
      # back to :unknown. NOT_FOUND arises on the read path (an unresolvable
      # subject or a scope the caller cannot see) and on delete (a key whose
      # subject IAM has never seen fails the whole batch). The write path never
      # returns it, since writing resolves or creates the subject.
      STATUS_REASONS = {
        GRPC::Core::StatusCodes::NOT_FOUND => :not_found,
        GRPC::Core::StatusCodes::PERMISSION_DENIED => :permission_denied,
        GRPC::Core::StatusCodes::UNAUTHENTICATED => :unauthenticated,
        GRPC::Core::StatusCodes::INVALID_ARGUMENT => :invalid_request,
        GRPC::Core::StatusCodes::UNAVAILABLE => :unavailable,
        GRPC::Core::StatusCodes::DEADLINE_EXCEEDED => :timeout
      }.freeze

      private

      def bearer_metadata(token)
        { 'authorization' => "Bearer #{token}" }
      end

      def service_token_credentials
        {
          header: ::Authn::IamDataAccessService::SERVICE_TOKEN_HEADER,
          token: ::Authn::IamDataAccessService.secret
        }
      end

      # Tracks the underlying failure and wraps it in a RequestError carrying a
      # machine-readable reason. Shared by the write and lookup paths;
      # `operation` names the failed call for the diagnostic message.
      def request_error(error, operation:)
        Gitlab::ErrorTracking.track_exception(error)

        if error.is_a?(::Authn::IamDataAccessService::ConfigurationError)
          return RequestError.new('IAM data access service is not configured', reason: :unavailable)
        end

        RequestError.new(
          "IAM Relationships API #{operation} failed: #{error.code}",
          reason: STATUS_REASONS.fetch(error.code, :unknown)
        )
      end
    end
  end
end
