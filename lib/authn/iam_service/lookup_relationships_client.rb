# frozen_string_literal: true

module Authn
  module IamService
    # gRPC client for the IAM Relationships API read path
    # (lookup.v1.LookupService#LookupRelationships).
    #
    # Shares its error contract, token metadata, and timeout with the write
    # path through DataAccessClient.
    class LookupRelationshipsClient < DataAccessClient
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
      rescue ::Authn::IamDataAccessService::ConfigurationError, GRPC::BadStatus => e
        raise request_error(e, operation: 'lookup')
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
        # (Authn::IamDataAccessService).
        build_stub(::Gitlab::Iam::Lookup::V1::LookupService::Stub, ::Authn::IamDataAccessService.grpc_address,
          timeout: TIMEOUT_SECONDS)
      end

      def secure_transport?
        ::Authn::IamDataAccessService.grpc_secure?
      end
    end
  end
end
