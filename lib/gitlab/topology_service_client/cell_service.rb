# frozen_string_literal: true

require 'gitlab/cells/topology_service'

module Gitlab
  module TopologyServiceClient
    class CellService < BaseService
      def get_cell_info
        response = client.get_cell(Gitlab::Cells::TopologyService::GetCellRequest.new(cell_name: cell_name))
        response.cell_info
      rescue GRPC::NotFound
        Gitlab::AppLogger.error(message: "Cell '#{cell_name}' not found on Topology Service")
        nil
      end

      private

      def service_class
        Gitlab::Cells::TopologyService::CellService::Stub
      end
    end
  end
end
