module GoogleApi
  module CloudPlatform
    class Client < GoogleApi::Authentication
      # Google::Apis::ContainerV1::ContainerService.new
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

      def projects_zones_clusters_create
        # TODO
      end
    end
  end
end
