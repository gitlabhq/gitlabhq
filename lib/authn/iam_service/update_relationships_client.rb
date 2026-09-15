# frozen_string_literal: true

module Authn
  module IamService
    # gRPC client for the IAM Relationships API write and delete path
    # (update.v1.UpdateService).
    #
    # Named after the IAM service it wraps, next to LookupRelationshipsClient
    # for the read path. Shares its error contract, token metadata, and timeout
    # with the read path through DataAccessClient.
    #
    # The public surface is scoped to role assignments: the relationships store
    # is a general tuple table, but the raw write and delete transports stay
    # private so callers cannot touch other relationship kinds through this
    # client.
    class UpdateRelationshipsClient < DataAccessClient
      # Grants roles by writing one ASSIGNMENT tuple per entry in a single
      # all-or-nothing write. Each assignment is a hash of the per-subject
      # pieces: assignee_id, resource_id, role_id.
      #
      # @param assignments [Array<Hash>] one hash per assignment
      # @param organization_uuid [String] the subjects' home organization UUID,
      #   used as the identity origin. IAM derives the organization it authorizes
      #   against from the caller's token, not from this value.
      # @param token [String] AR-scoped JWT presented as a bearer credential
      # @return [Update::V1::WriteRelationshipsResponse]
      def grant_roles(assignments, organization_uuid:, token:)
        inputs = assignments.map do |a|
          assignment_input(organization_uuid, a.fetch(:assignee_id), a.fetch(:resource_id), a.fetch(:role_id))
        end

        write_relationships(inputs, token: token)
      end

      # Revokes role assignments by deleting one ASSIGNMENT tuple per key in a
      # single all-or-nothing delete. Each key is a hash of the per-subject
      # pieces: assignee_id, resource_id. Deleting a key with no matching tuple
      # succeeds for a subject IAM has already seen, but IAM resolves every
      # key's subject first and fails the whole batch with NOT_FOUND when any
      # subject was never granted anything.
      #
      # @param keys [Array<Hash>] one hash per key
      # @param organization_uuid [String] the subjects' home organization UUID
      # @param token [String] AR-scoped JWT presented as a bearer credential
      # @return [Update::V1::DeleteRelationshipsResponse]
      def revoke_roles(keys, organization_uuid:, token:)
        inputs = keys.map do |key|
          relationship_key(organization_uuid, key.fetch(:assignee_id), key.fetch(:resource_id))
        end

        delete_relationships(inputs, token: token)
      end

      private

      # Upserts the given tuples. All-or-nothing on the server.
      def write_relationships(relationship_inputs, token:)
        request = ::Gitlab::Iam::Update::V1::WriteRelationshipsRequest.new(
          relationships: relationship_inputs
        )

        client.write_relationships(request, metadata: bearer_metadata(token))
      rescue ::Authn::IamDataAccessService::ConfigurationError, GRPC::BadStatus => e
        raise request_error(e, operation: 'write')
      end

      # Deletes the given tuples by key. All-or-nothing on the server.
      def delete_relationships(relationship_keys, token:)
        request = ::Gitlab::Iam::Update::V1::DeleteRelationshipsRequest.new(
          keys: relationship_keys
        )

        client.delete_relationships(request, metadata: bearer_metadata(token))
      rescue ::Authn::IamDataAccessService::ConfigurationError, GRPC::BadStatus => e
        raise request_error(e, operation: 'delete')
      end

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

      # A delete key is the write input without a role: IAM stores one
      # ASSIGNMENT per (subject, object), so the key alone identifies the tuple.
      def relationship_key(organization_uuid, assignee_id, resource_id)
        ::Gitlab::Iam::Relationships::V1::RelationshipKey.new(
          subject: ::Gitlab::Iam::Relationships::V1::Subject.new(
            identity: ::Gitlab::Iam::Relationships::V1::Identity.new(
              origin: :ORIGIN_ORGANIZATION,
              origin_id: organization_uuid,
              local_id: assignee_id.to_s
            )
          ),
          object: ::Gitlab::Iam::Relationships::V1::Object.new(id: resource_id),
          kind: :KIND_ASSIGNMENT
        )
      end

      def client
        # Address + transport config is owned by the IAM data access service
        # (Authn::IamDataAccessService).
        build_stub(::Gitlab::Iam::Update::V1::UpdateService::Stub, ::Authn::IamDataAccessService.grpc_address,
          timeout: TIMEOUT_SECONDS)
      end

      def secure_transport?
        ::Authn::IamDataAccessService.grpc_secure?
      end
    end
  end
end
