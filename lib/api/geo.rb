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
        attrs = attributes_for_keys [:projects]

        Geo::ScheduleRepoUpdateService.new(attrs[:projects]).execute
      end
    end
  end
end
