# frozen_string_literal: true

module Authn
  module IamService
    # gRPC client for the IAM Relationships API read path
    # (lookup.v1.LookupService#LookupRelationships and #LookupResources).
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
          filter: lookup_filter(kinds, role_ids),
          page_size: page_size.to_i,
          page_token: page_token.to_s
        )

        client.lookup_relationships(request, metadata: bearer_metadata(token))
      rescue ::Authn::IamDataAccessService::ConfigurationError, GRPC::BadStatus => e
        raise request_error(e, operation: 'lookup')
      end

      # Reads one subject's relationships across the organization, one keyset
      # page at a time (lookup.v1.LookupService#LookupResources). IAM allows
      # this only when the caller is the subject or the organization owner.
      #
      # @param subject_id [Integer, String] the subject's local user id.
      # @param organization_uuid [String] the subject's identity origin, as
      #   used when the relationship was written.
      # @param kinds, role_ids, page_size, page_token, token as for #lookup.
      # @return [Lookup::V1::LookupResourcesResponse]
      def lookup_resources(subject_id:, organization_uuid:, kinds:, role_ids:, page_size:, page_token:, token:)
        request = ::Gitlab::Iam::Lookup::V1::LookupResourcesRequest.new(
          subject: ::Gitlab::Iam::Relationships::V1::Subject.new(
            identity: ::Gitlab::Iam::Relationships::V1::Identity.new(
              origin: :ORIGIN_ORGANIZATION,
              origin_id: organization_uuid,
              local_id: subject_id.to_s
            )
          ),
          filter: lookup_filter(kinds, role_ids),
          page_size: page_size.to_i,
          page_token: page_token.to_s
        )

        client.lookup_resources(request, metadata: bearer_metadata(token))
      rescue ::Authn::IamDataAccessService::ConfigurationError, GRPC::BadStatus => e
        raise request_error(e, operation: 'lookup resources')
      end

      private

      def lookup_filter(kinds, role_ids)
        ::Gitlab::Iam::Lookup::V1::LookupFilter.new(
          kinds: kinds,
          roles: role_ids.map { |id| ::Gitlab::Iam::Relationships::V1::Role.new(id: id) }
        )
      end

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
