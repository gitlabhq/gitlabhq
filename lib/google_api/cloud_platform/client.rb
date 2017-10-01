require 'google/apis/container_v1'

module GoogleApi
  module CloudPlatform
    class Client < GoogleApi::Auth
      DEFAULT_MACHINE_TYPE = 'n1-standard-1'

      class << self
        def session_key_for_token
          :cloud_platform_access_token
        end
      end

      def scope
        'https://www.googleapis.com/auth/cloud-platform'
      end

      def projects_zones_clusters_get(project_id, zone, cluster_id)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        begin
          cluster = service.get_zone_cluster(project_id, zone, cluster_id)
        rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
          return e
        end

        puts "#{self.class.name} - #{__callee__}: cluster: #{cluster.inspect}"
        cluster
      end

      def projects_zones_clusters_create(project_id, zone, cluster_name, cluster_size, machine_type:)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        request_body = Google::Apis::ContainerV1::CreateClusterRequest.new(
            {
              "cluster": {
                "name": cluster_name,
                "initial_node_count": cluster_size,
                "node_config": {
                  "machine_type": machine_type # Default 3.75 GB, if ommit
                }
              }
            }
          )

        begin
          operation = service.create_cluster(project_id, zone, request_body)
        rescue Google::Apis::ServerError, Google::Apis::ClientError, Google::Apis::AuthorizationError => e
          return e
        end

        puts "#{self.class.name} - #{__callee__}: operation: #{operation.inspect}"
        operation
      end

      def projects_zones_operations(project_id, zone, operation_id)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        begin
          operation = service.get_zone_operation(project_id, zone, operation_id)
        rescue Google::Apis::ClientError, Google::Apis::AuthorizationError => e
          return e
        end

        puts "#{self.class.name} - #{__callee__}: operation: #{operation.inspect}"
        operation
      end

      def parse_operation_id(self_link)
        self_link.match(/projects\/.*\/zones\/.*\/operations\/(.*)/)[1]
      end
    end
  end
end
