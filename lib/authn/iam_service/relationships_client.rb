# frozen_string_literal: true

module Authn
  module IamService
    # gRPC client for the IAM Relationships API write path (update.v1.UpdateService).
    #
    # Callers present an AR-scoped bearer token minted by the Rails token exchange
    # (Authn::TokenExchange::TokenIssuer). IAM validates the token and authorizes
    # the caller server-side -- this client does not perform authorization.
    class RelationshipsClient < BaseClient
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
      # limit of tuples in a single all-or-nothing transaction.
      TIMEOUT_SECONDS = 15

      # Maps the gRPC statuses the IAM Relationships API returns on a failed
      # write to a machine-readable reason for the caller to translate. Keyed by
      # the integer gRPC status code (GRPC::BadStatus#code); unlisted statuses
      # fall back to :unknown.
      WRITE_ERROR_REASONS = {
        GRPC::Core::StatusCodes::PERMISSION_DENIED => :permission_denied,
        GRPC::Core::StatusCodes::UNAUTHENTICATED => :unauthenticated,
        GRPC::Core::StatusCodes::INVALID_ARGUMENT => :invalid_request,
        GRPC::Core::StatusCodes::UNAVAILABLE => :unavailable,
        GRPC::Core::StatusCodes::DEADLINE_EXCEEDED => :timeout
      }.freeze

      # Assigns roles by writing one ASSIGNMENT tuple per entry in a single
      # all-or-nothing write. Each assignment is a hash of the per-subject
      # pieces: assignee_id, resource_id, role_id.
      #
      # @param assignments [Array<Hash>] one hash per assignment
      # @param organization_uuid [String] the subjects' home organization UUID,
      #   used as the identity origin. IAM derives the organization it authorizes
      #   against from the caller's token, not from this value.
      # @param token [String] AR-scoped JWT presented as a bearer credential
      # @return [Update::V1::WriteRelationshipsResponse]
      def assign_roles(assignments, organization_uuid:, token:)
        inputs = assignments.map do |a|
          assignment_input(organization_uuid, a.fetch(:assignee_id), a.fetch(:resource_id), a.fetch(:role_id))
        end

        write_relationships(inputs, token: token)
      end

      # Upserts the given assignment tuples. All-or-nothing on the server.
      #
      # @param relationship_inputs [Array<Relationships::V1::RelationshipInput>]
      # @param token [String] AR-scoped JWT presented as a bearer credential
      # @return [Update::V1::WriteRelationshipsResponse]
      def write_relationships(relationship_inputs, token:)
        request = ::Gitlab::Iam::Update::V1::WriteRelationshipsRequest.new(
          relationships: relationship_inputs
        )

        client.write_relationships(request, metadata: bearer_metadata(token))
      rescue ::Authn::IamDataAccessService::ConfigurationError => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError.new('IAM data access service is not configured', reason: :unavailable)
      rescue GRPC::BadStatus => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError.new(
          "IAM Relationships API write failed: #{e.code}",
          reason: WRITE_ERROR_REASONS.fetch(e.code, :unknown)
        )
      end

      private

      def assignment_input(organization_uuid, assignee_id, resource_id, role_id)
        ::Gitlab::Iam::Relationships::V1::RelationshipInput.new(
          subject: ::Gitlab::Iam::Relationships::V1::Subject.new(
            identity: ::Gitlab::Iam::Relationships::V1::Identity.new(
              origin: :ORIGIN_ORGANIZATION,
              origin_id: organization_uuid,
              local_id: assignee_id.to_s
            )
          ),
          object: ::Gitlab::Iam::Relationships::V1::Object.new(id: resource_id),
          kind: :KIND_ASSIGNMENT,
          role: ::Gitlab::Iam::Relationships::V1::Role.new(id: role_id)
        )
      end

      def client
        # Address + transport config is owned by the IAM data access service
        # (Authn::IamDataAccessService). It returns a tls://-prefixed address
        # outside development.
        #
        # TODO: add mTLS support when the IAM data access service exposes it.
        build_stub(::Gitlab::Iam::Update::V1::UpdateService::Stub, ::Authn::IamDataAccessService.grpc_address,
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
