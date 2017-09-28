require 'google/apis/container_v1'

module GoogleApi
  module CloudPlatform
    class Client < GoogleApi::Authentication
      class << self
        def token_in_session
          :cloud_platform_access_token
        end
      end

      def scope
        'https://www.googleapis.com/auth/cloud-platform'
      end

      def projects_zones_clusters_get(project_id, zone, cluster_id)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        cluster = service.get_zone_cluster(project_id, zone, cluster_id)
        puts "#{self.class.name} - #{__callee__}: cluster: #{cluster.inspect}"
        cluster
      end

      # Responce exmaple 
      # TODO: machine_type : Defailt 3.75 GB
      def projects_zones_clusters_create(project_id, zone, cluster_name, cluster_size:, machine_type:)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        request_body = Google::Apis::ContainerV1::CreateClusterRequest.new(
            {
              "cluster": {
                "name": cluster_name,
                "initial_node_count": cluster_size
              }
            }
          )

        begin
          operation = service.create_cluster(project_id, zone, request_body)
        rescue Google::Apis::ClientError, Google::Apis::AuthorizationError => e
          puts "#{self.class.name} - #{__callee__}: Could not create cluster #{cluster_name}: #{e}"
          # TODO: Error
        end
        puts "#{self.class.name} - #{__callee__}: operation: #{operation.inspect}"
        operation
      end

      def projects_zones_operations(project_id, zone, operation_id)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        operation = service.get_zone_operation(project_id, zone, operation_id)
        puts "#{self.class.name} - #{__callee__}: operation: #{operation.inspect}"
        operation
      end

      def parse_self_link(self_link)
        ret = self_link.match(/projects\/(.*)\/zones\/(.*)\/operations\/(.*)/)

        return ret[1], ret[2], ret[3] # project_id, zone, operation_id
      end
    end
  end
end
