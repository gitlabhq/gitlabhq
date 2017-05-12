module API
  class Geo < Grape::API
    resource :geo do
      # Verify the GitLab Geo transfer request is valid
      # All transfers use the Authorization header to pass a JWT
      # payload.
      #
      # For LFS objects, validate the object ID exists in the DB
      # and that the object ID matches the requested ID. This is
      # a sanity check against some malicious client requesting
      # a random file path.
      params do
        requires :type, type: String, desc: 'File transfer type (e.g. lfs)'
        requires :id, type: Integer, desc: 'The DB ID of the file'
      end
      get 'transfers/:type/:id' do
        service = ::Geo::FileUploadService.new(params, headers['Authorization'])
        response = service.execute

        unauthorized! unless response.present?

        if response[:code] == :ok
          file = response[:file]
          present_file!(file.path, file.filename)
        else
          status response[:code]
          response
        end
      end

      #  Get node information (e.g. health, repos synced, repos failed, etc.)
      #
      # Example request:
      #   GET /geo/status
      get 'status' do
        authenticate_by_gitlab_geo_node_token!
        require_node_to_be_secondary!
        require_node_to_have_tracking_db!

        present GeoNodeStatus.new(id: Gitlab::Geo.current_node.id), with: Entities::GeoNodeStatus
      end

      # Enqueue a batch of IDs of wiki's projects to have their
      # wiki repositories updated
      #
      # Example request:
      #   POST /geo/refresh_wikis
      post 'refresh_wikis' do
        authenticated_as_admin!
        require_node_to_be_enabled!
        required_attributes! [:projects]
        ::Geo::ScheduleWikiRepoUpdateService.new(params[:projects]).execute
      end

      # Receive event streams from primary and enqueue changes
      #
      # Example request:
      #   POST /geo/receive_events
      post 'receive_events' do
        authenticate_by_gitlab_geo_token!
        require_node_to_be_enabled!
        required_attributes! %w(event_name)

        case params['event_name']
        when 'key_create', 'key_destroy'
          required_attributes! %w(key id)
          ::Geo::ScheduleKeyChangeService.new(params).execute
        when 'repository_update'
          required_attributes! %w(event_name project_id project)
          ::Geo::ScheduleRepoFetchService.new(params).execute
        when 'push'
          required_attributes! %w(event_name project_id project)
          ::Geo::ScheduleRepoUpdateService.new(params).execute
        when 'tag_push'
          required_attributes! %w(event_name project_id project)
          ::Geo::ScheduleWikiRepoUpdateService.new(params).execute
        when 'project_create'
          required_attributes! %w(event_name project_id)
          ::Geo::ScheduleRepoCreateService.new(params).execute
        when 'project_destroy'
          required_attributes! %w(event_name project_id path_with_namespace)
          ::Geo::ScheduleRepoDestroyService.new(params).execute
        when 'project_rename'
          required_attributes! %w(event_name project_id path_with_namespace old_path_with_namespace)
          ::Geo::ScheduleRepoMoveService.new(params).execute
        when 'project_transfer'
          required_attributes! %w(event_name project_id path_with_namespace old_path_with_namespace)
          ::Geo::ScheduleRepoMoveService.new(params).execute
        end
      end
    end

    helpers do
      def authenticate_by_gitlab_geo_node_token!
        auth_header = headers['Authorization']

        unless auth_header && Gitlab::Geo::JwtRequestDecoder.new(auth_header).decode
          unauthorized!
        end
      end

      def require_node_to_be_enabled!
        forbidden! 'Geo node is disabled.' unless Gitlab::Geo.current_node&.enabled?
      end

      def require_node_to_be_secondary!
        forbidden! 'Geo node is not secondary node.' unless Gitlab::Geo.current_node&.secondary?
      end

      def require_node_to_have_tracking_db!
        not_found! 'Geo node does not have its tracking database enabled.' unless Gitlab::Geo.configured?
      end
    end
  end
end
