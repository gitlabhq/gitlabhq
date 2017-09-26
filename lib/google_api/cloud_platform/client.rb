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
      # {"name":"operation-1506424047439-0293f57c","operationType":"CREATE_CLUSTER","selfLink":"https://container.googleapis.com/v1/projects/696404988091/zones/us-central1-a/operations/operation-1506424047439-0293f57c","startTime":"2017-09-26T11:07:27.439033158Z","status":"RUNNING","targetLink":"https://container.googleapis.com/v1/projects/696404988091/zones/us-central1-a/clusters/gke-test-creation","zone":"us-central1-a"}
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
          Rails.logger.error("#{self.class.name}: Could not create cluster #{cluster_name}: #{e}")
        end
        puts "#{self.class.name} - #{__callee__}: operation: #{operation.inspect}"
        operation
      end

      def projects_zones_operations(project_id, zone, operation_id)
        service = Google::Apis::ContainerV1::ContainerService.new
        service.authorization = access_token

        operation = service.get_zone_operation(project_id, zone, operation_id)
        operation
      end

      def wait_operation_done(self_link)
        running = true

        ret = self_link.match(/projects\/(.*)\/zones\/(.*)\/operations\/(.*)/)
        project_id = ret[1]
        zone = ret[2]
        operation_id = ret[3]

        while running
          operation = projects_zones_operations(project_id, zone, operation_id)
          if operation.status != 'RUNNING'
            running = false
          end
        end
      end
    end
  end
end
