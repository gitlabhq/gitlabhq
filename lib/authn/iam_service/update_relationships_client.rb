# frozen_string_literal: true

module Authn
  module IamService
    # gRPC client for the IAM Relationships API write path (update.v1.UpdateService).
    #
    # Named after the IAM service it wraps, next to LookupRelationshipsClient
    # for the read path. Shares its error contract, token metadata, and timeout
    # with the read path through DataAccessClient.
    class UpdateRelationshipsClient < DataAccessClient
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
      rescue ::Authn::IamDataAccessService::ConfigurationError, GRPC::BadStatus => e
        raise request_error(e, operation: 'write')
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
        build_stub(::Gitlab::Iam::Update::V1::UpdateService::Stub, ::Authn::IamDataAccessService.grpc_address,
          timeout: TIMEOUT_SECONDS)
      end
    end
  end
end
