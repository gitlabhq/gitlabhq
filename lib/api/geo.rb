module API
  class Geo < Grape::API
    before { authenticated_as_admin! }

    resource :geo do

      # Enqueue a batch of IDs of modified projects to have their
      # repositories updated
      #
      # Example request:
      #   POST /refresh_projects
      post 'refresh_projects' do
        required_attributes! [:projects]
        ::Geo::ScheduleRepoUpdateService.new(params[:projects]).execute
      end

      # Enqueue a batch of IDs of wiki's projects to have their
      # wiki repositories updated
      #
      # Example request:
      #   POST /refresh_wikis
      post 'refresh_wikis' do
        required_attributes! [:projects]
        ::Geo::ScheduleWikiRepoUpdateService.new(params[:projects]).execute
      end
    end
  end
end
