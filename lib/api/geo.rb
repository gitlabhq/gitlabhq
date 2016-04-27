module API
  class Geo < Grape::API
    resource :geo do
      # Enqueue a batch of IDs of wiki's projects to have their
      # wiki repositories updated
      #
      # Example request:
      #   POST /geo/refresh_wikis
      post 'refresh_wikis' do
        authenticated_as_admin!
        required_attributes! [:projects]
        ::Geo::ScheduleWikiRepoUpdateService.new(params[:projects]).execute
      end

      # Receive event streams from primary and enqueue changes
      #
      # Example request:
      #   POST /geo/receive_events
      post 'receive_events' do
        authenticate_by_gitlab_geo_token!
        required_attributes! %w(event_name)

        case params['event_name']
        when 'key_create', 'key_destroy'
          required_attributes! %w(key id)
          ::Geo::ScheduleKeyChangeService.new(params).execute
        when 'push'
          required_attributes! %w(event_name project_id project)
          ::Geo::ScheduleRepoUpdateService.new(params).execute
        when 'tag_push'
          required_attributes! %w(event_name project_id project)
          ::Geo::ScheduleWikiRepoUpdateService.new(params).execute
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
  end
end
