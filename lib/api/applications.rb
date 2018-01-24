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
    end
  end
end
