# frozen_string_literal: true

require 'gitlab/cells/topology_service'

module Gitlab
  module TopologyServiceClient
    class CellService < BaseService
      def get_cell_info
        response = client.get_cell(Gitlab::Cells::TopologyService::GetCellRequest.new(cell_id: cell_id))
        response.cell_info
      rescue GRPC::NotFound
        Gitlab::AppLogger.error(message: "Cell '#{cell_id}' not found on Topology Service")
        nil
      end

      def cell_sequence_ranges
        cell_info = get_cell_info
        return unless cell_info.present?

        cell_info.sequence_ranges
      end

      private

      def service_class
        Gitlab::Cells::TopologyService::CellService::Stub
      end
    end
  end
end
