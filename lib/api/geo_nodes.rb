module API
  class GeoNodes < Grape::API
    include PaginationParams
    include APIGuard

    before { authenticated_as_admin! }

    resource :geo_nodes do
      # Get all Geo node information
      #
      # Example request:
      #   GET /geo_nodes
      desc 'Retrieves the available Geo nodes' do
        success Entities::GeoNode
      end

      get do
        nodes = GeoNode.all

        present paginate(nodes), with: Entities::GeoNode
      end

      # Get all Geo node statuses
      #
      # Example request:
      #   GET /geo_nodes/status
      desc 'Get status for all Geo nodes' do
        success GeoNodeStatusEntity
      end
      get '/status' do
        status = GeoNodeStatus.all

        present paginate(status), with: GeoNodeStatusEntity
      end

      # Get all Geo node information
      #
      # Example request:
      #   GET /geo_nodes/:id
      desc 'Get a single GeoNode' do
        success Entities::GeoNode
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the node'
      end
      get ':id' do
        node = GeoNode.find_by(id: params[:id])

        not_found!('GeoNode') unless node

        present node, with: Entities::GeoNode
      end

      # Get Geo metrics for a single node
      #
      # Example request:
      #   GET /geo_nodes/:id/status
      desc 'Get metrics for a single Geo node' do
        success Entities::GeoNode
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the node'
      end
      get ':id/status' do
        geo_node = GeoNode.find(params[:id])

        not_found('Geo node not found') unless geo_node

        status =
          if geo_node.current?
            GeoNodeStatus.current_node_status
          else
            geo_node.status
          end

        not_found!('Status for Geo node not found') unless status

        present status, with: ::GeoNodeStatusEntity
      end
    end
  end
end
