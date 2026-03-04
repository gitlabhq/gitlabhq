# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    class ClaimService < BaseService
      include Singleton

      def begin_update(create_records: [], destroy_records: [], deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new(
          create_records: create_records,
          destroy_records: destroy_records,
          cell_id: cell_id
        )

        client.begin_update(request, deadline: deadline)
      end

      def commit_update(uuid, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::CommitUpdateRequest.new(
          lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid),
          cell_id: cell_id
        )
        client.commit_update(request, deadline: deadline)
      end

      def rollback_update(uuid, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::RollbackUpdateRequest.new(
          lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: uuid),
          cell_id: cell_id
        )
        client.rollback_update(request, deadline: deadline)
      end

      def list_leases(cursor: nil, limit: nil, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::ListLeasesRequest.new(
          next: cursor,
          limit: limit,
          cell_id: cell_id
        )

        client.list_leases(request, deadline: deadline)
      end

      def list_records(source_type: nil, bucket_types: nil, source_id_gt: nil, source_id_lte: nil, deadline: nil)
        request = Gitlab::Cells::TopologyService::Claims::V1::ListRecordsRequest.new(
          source_type: source_type,
          bucket_types: bucket_types,
          source_id_gt: source_id_gt,
          source_id_lte: source_id_lte,
          cell_id: cell_id
        )

        client.list_records(request, deadline: deadline)
      end

      private

      def service_class
        Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub
      end
    end
  end
end
