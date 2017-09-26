module GoogleApi
  module CloudPlatform
    class Client < GoogleApi::Authentication
      # Google::Apis::ContainerV1::ContainerService.new

      class << self
        def token_in_session
          :cloud_platform_access_token
        end
      end

      def scope
        'https://www.googleapis.com/auth/cloud-platform'
      end

      def projects_zones_clusters_get
        # TODO: 
        # service = Google::Apis::ContainerV1::ContainerService.new
        # service.authorization = access_token
        # project_id = params['project_id']
        # ...
        # response = service.list_zone_clusters(project_id, zone)
        response
      end

      def projects_zones_clusters_create(gcp_project_id, cluster_zone, cluster_name, cluster_size)
        # TODO: Google::Apis::ContainerV1::ContainerService.new

        # TODO: Debug
        {
          'end_point' => 'https://111.111.111.111',
          'ca_cert' => 'XXXXXXXXXXXXXXXXXX',
          'username' => 'AAA',
          'password' => 'BBB'
        }
      end
    end
  end
end
