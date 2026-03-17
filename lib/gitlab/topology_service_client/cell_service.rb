# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    CellNotFoundError = Class.new(StandardError)

    class CellService < BaseService
      def get_cell_info
        response = client.get_cell(Gitlab::Cells::TopologyService::GetCellRequest.new(cell_id: cell_id))
        response.cell_info
      rescue GRPC::NotFound
        handle_cell_not_found
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

      def handle_cell_not_found
        error_message = "Cell '#{cell_id}' not found on Topology Service"
        Gitlab::AppLogger.error(message: error_message)

        raise CellNotFoundError, error_message
      end
    end
  end
end
