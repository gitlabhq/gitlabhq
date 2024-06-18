# frozen_string_literal: true

module API
  # External applications API
  class Applications < ::API::Base
    before { authenticated_as_admin! }

    feature_category :system_access

    resource :applications do
      desc 'Create a new application' do
        detail 'This feature was introduced in GitLab 10.5'
        success code: 200, model: Entities::ApplicationWithSecret
      end
      params do
        requires :name, type: String, desc: 'Name of the application.', documentation: { example: 'MyApplication' }
        requires :redirect_uri, type: String, desc: 'Redirect URI of the application.', documentation: { example: 'https://redirect.uri' }
        requires :scopes, type: String,
          desc: 'Scopes of the application. You can specify multiple scopes by separating\
                                 each scope using a space',
          allow_blank: false

        optional :confidential,
          type: Boolean,
          default: true,
          desc: 'The application is used where the client secret can be kept confidential. Native mobile apps \
                        and Single Page Apps are considered non-confidential. Defaults to true if not supplied'
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
        detail 'List all registered applications'
        success Entities::Application
        is_array true
      end
      get do
        applications = ApplicationsFinder.new.execute
        present applications, with: Entities::Application
      end

      desc 'Delete an application' do
        detail 'Delete a specific application'
        success code: 204
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the application (not the application_id)'
      end
      delete ':id' do
        application = ApplicationsFinder.new(params).execute
        break not_found!('Application') unless application

        application.destroy

        no_content!
      end

      desc 'Renew an application secret' do
        detail 'Renew the secret of a specific application'
        success code: 200, model: Entities::ApplicationWithSecret
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the application (not the application_id)'
      end
      post ':id/renew-secret' do
        application = ApplicationsFinder.new(params).execute
        break not_found!('Application') unless application

        application.renew_secret

        if application.save
          present application, with: Entities::ApplicationWithSecret
        else
          render_validation_error!(application)
        end
      end
    end
  end
end
