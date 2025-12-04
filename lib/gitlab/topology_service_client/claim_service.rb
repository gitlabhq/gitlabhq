# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    class ClaimService < BaseService
      include Singleton

      delegate :begin_update, :commit_update, :rollback_update, to: :client

      def list_leases(cursor: nil, limit: nil, deadline: nil)
        req = Gitlab::Cells::TopologyService::Claims::V1::ListLeasesRequest.new(
          cell_id: cell_id,
          next: cursor,
          limit: limit
        )

        client.list_leases(req, deadline: deadline)
      end

      private

      def service_class
        Gitlab::Cells::TopologyService::Claims::V1::ClaimService::Stub
      end
    end
  end
end
