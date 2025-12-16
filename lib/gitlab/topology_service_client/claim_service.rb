# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    class ClaimService < BaseService
      include Singleton

      delegate :begin_update, to: :client

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
          cell_id: cell_id,
          next: cursor,
          limit: limit
        )

        client.list_leases(request, deadline: deadline)
      end

      private

      def service_class
        Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub
      end
    end
  end
end
