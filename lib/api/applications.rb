# frozen_string_literal: true

module API
  # External applications API
  class Applications < Grape::API
    before { authenticated_as_admin! }

    resource :applications do
      desc 'Create a new application' do
        detail 'This feature was introduced in GitLab 10.5'
        success Entities::ApplicationWithSecret
      end
      params do
        requires :name, type: String, desc: 'Application name'
        requires :redirect_uri, type: String, desc: 'Application redirect URI'
        requires :scopes, type: String, desc: 'Application scopes'
      end
      post do
        application = Doorkeeper::Application.new(declared_params)

        if application.save
          present application, with: Entities::ApplicationWithSecret
        else
          render_validation_error! application
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      desc 'Get applications' do
        success Entities::ApplicationWithSecret
      end
      get do
        applications = Doorkeeper::Application.where("owner_id IS NULL")
        present applications, with: Entities::Application
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      desc 'Delete an application'
      delete ':id' do
        Doorkeeper::Application.find_by(id: params[:id]).destroy

        status 204
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
