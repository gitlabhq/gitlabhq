# frozen_string_literal: true

module API
  # External applications API
  class Applications < ::API::Base
    before { authenticated_as_admin! }

    feature_category :authentication_and_authorization

    resource :applications do
      desc 'Create a new application' do
        detail 'This feature was introduced in GitLab 10.5'
        success Entities::ApplicationWithSecret
      end
      params do
        requires :name, type: String, desc: 'Application name'
        requires :redirect_uri, type: String, desc: 'Application redirect URI'
        requires :scopes, type: String, desc: 'Application scopes'

        optional :confidential, type: Boolean, default: true,
          desc: 'Application will be used where the client secret is confidential'
      end
      post do
        application = Doorkeeper::Application.new(declared_params)

        if application.save
          present application, with: Entities::ApplicationWithSecret
        else
          render_validation_error! application
        end
      end

      desc 'Get applications' do
        success Entities::Application
      end
      get do
        applications = ApplicationsFinder.new.execute
        present applications, with: Entities::Application
      end

      desc 'Delete an application'
      delete ':id' do
        application = ApplicationsFinder.new(params).execute
        break not_found!('Application') unless application

        application.destroy

        no_content!
      end
    end
  end
end
