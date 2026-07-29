# frozen_string_literal: true

module Authn
  module IamService
    # gRPC client for the IAM Relationships API read path
    # (lookup.v1.LookupService#LookupRelationships).
    #
    # Callers present an AR-scoped bearer token minted by the Rails token exchange
    # (Authn::TokenExchange::TokenIssuer). IAM validates the token and authorizes
    # the caller server-side -- this client does not perform authorization.
    class LookupRelationshipsClient < BaseClient
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

      # A read returns one keyset page bounded by page_size, so a single call
      # stays small; this mirrors the write client's headroom.
      TIMEOUT_SECONDS = 15

      # Maps the gRPC statuses the IAM Relationships API returns on a failed
      # lookup to a machine-readable reason for the caller to translate. Keyed by
      # the integer gRPC status code (GRPC::BadStatus#code); unlisted statuses
      # fall back to :unknown. NOT_FOUND covers an unresolvable subject or a
      # scope the caller cannot see.
      LOOKUP_ERROR_REASONS = {
        GRPC::Core::StatusCodes::NOT_FOUND => :not_found,
        GRPC::Core::StatusCodes::PERMISSION_DENIED => :permission_denied,
        GRPC::Core::StatusCodes::UNAUTHENTICATED => :unauthenticated,
        GRPC::Core::StatusCodes::INVALID_ARGUMENT => :invalid_request,
        GRPC::Core::StatusCodes::UNAVAILABLE => :unavailable,
        GRPC::Core::StatusCodes::DEADLINE_EXCEEDED => :timeout
      }.freeze

      # Reads relationships for the given objects, optionally filtered by kind
      # and role, one keyset page at a time.
      #
      # @param objects [Array<Hash>] each { id:, ancestor_ids: [] }; empty scans
      #   the whole organization (IAM requires the org owner for that).
      #   ancestor_ids names at most one ancestor the caller administers;
      #   holding the artifact_admin role on that ancestor authorizes the lookup
      #   for the object. It authorizes only and never expands the result. IAM
      #   does not verify the hierarchy, so the caller must ensure the named
      #   object really is an ancestor.
      # @param kinds [Array<Symbol>] relationship kinds as IAM enum symbols
      #   (e.g. :KIND_ASSIGNMENT).
      # @param role_ids [Array<String>] role UUIDs to filter by.
      # @param page_size [Integer, nil] nil or 0 uses the IAM default.
      # @param page_token [String, nil] nil or empty starts at the first page.
      # @param token [String] AR-scoped JWT presented as a bearer credential.
      # @return [Lookup::V1::LookupRelationshipsResponse]
      def lookup(objects:, kinds:, role_ids:, page_size:, page_token:, token:)
        request = ::Gitlab::Iam::Lookup::V1::LookupRelationshipsRequest.new(
          objects: objects.map { |object| object_input(object) },
          filter: ::Gitlab::Iam::Lookup::V1::LookupFilter.new(
            kinds: kinds,
            roles: role_ids.map { |id| ::Gitlab::Iam::Relationships::V1::Role.new(id: id) }
          ),
          page_size: page_size.to_i,
          page_token: page_token.to_s
        )

        client.lookup_relationships(request, metadata: bearer_metadata(token))
      rescue ::Authn::IamDataAccessService::ConfigurationError => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError.new('IAM data access service is not configured', reason: :unavailable)
      rescue GRPC::BadStatus => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError.new(
          "IAM Relationships API lookup failed: #{e.code}",
          reason: LOOKUP_ERROR_REASONS.fetch(e.code, :unknown)
        )
      end

      private

      def object_input(object)
        ::Gitlab::Iam::Relationships::V1::Object.new(
          id: object.fetch(:id),
          ancestors: Array(object[:ancestor_ids]).map do |ancestor_id|
            ::Gitlab::Iam::Relationships::V1::Object.new(id: ancestor_id)
          end
        )
      end

      def client
        # Address + transport config is owned by the IAM data access service
        # (Authn::IamDataAccessService). It returns a tls://-prefixed address
        # outside development.
        build_stub(::Gitlab::Iam::Lookup::V1::LookupService::Stub, ::Authn::IamDataAccessService.grpc_address,
          timeout: TIMEOUT_SECONDS)
      end

      def bearer_metadata(token)
        { 'authorization' => "Bearer #{token}" }
      end

      def service_token_credentials
        {
          header: ::Authn::IamDataAccessService::SERVICE_TOKEN_HEADER,
          token: ::Authn::IamDataAccessService.secret
        }
      end
    end
  end
end
