# frozen_string_literal: true

module API
  # User applications API
  class UserApplications < ::API::Base
    before do
      set_current_organization
      authenticate!
    end

    feature_category :system_access

    resource :user do
      resource :applications do
        desc 'Create an application' do
          detail 'Creates a new OAuth application for the authenticated user. ' \
            'This feature was introduced in GitLab 19.0'
          success code: 201, model: Entities::ApplicationWithSecret
          tags ['applications']
        end
        params do
          requires :name, type: String, desc: 'Name of the application.', documentation: { example: 'MyApplication' }
          requires :redirect_uri, type: String, desc: 'Redirect URI of the application.', documentation: { example: 'https://redirect.uri' }
          requires :scopes, type: String,
            desc: 'Scopes available to the application. Separate multiple scopes with a space.',
            allow_blank: false

          optional :confidential,
            type: Boolean,
            default: true,
            desc: 'If `true`, the application can securely store client credentials, such as the ' \
              'client secret. Non-confidential applications, such as native mobile apps and ' \
              'Single Page Apps might expose client credentials. If unset, defaults to `true`.'
        end
        route_setting :authorization, permissions: :create_oauth_application, boundary_type: :user
        post do
          create_params = declared_params(include_missing: false)
          application = ::Applications::CreateService.new(
            current_user,
            request,
            create_params.merge(owner: current_user, organization: Current.organization)
          ).execute

          if application.persisted?
            present application, with: Entities::ApplicationWithSecret
          else
            render_validation_error! application
          end
        end

        desc 'List all applications' do
          detail 'Lists all applications owned by the authenticated user.'
          success Entities::Application
          is_array true
          failure [[401, 'Unauthorized'], [403, 'Forbidden']]
          tags ['applications']
        end
        route_setting :authorization, permissions: :read_oauth_application, boundary_type: :user
        get do
          present paginate(current_user.oauth_applications), with: Entities::Application
        end

        desc 'Retrieve an application' do
          detail 'Retrieves details of a specific application owned by the authenticated user.'
          success Entities::Application
          tags ['applications']
        end
        params do
          requires :id, type: Integer, desc: 'ID of the application. Differs from the `application_id`.'
        end
        route_setting :authorization, permissions: :read_oauth_application, boundary_type: :user
        get ':id' do
          application = ::Authn::OauthApplication.find_by_id(params[:id])
          break not_found!('Application') unless application

          authorize! :read_oauth_application, application

          present application, with: Entities::Application
        end

        desc 'Delete an application' do
          detail 'Deletes a specified application owned by the authenticated user.'
          success code: 204
          tags ['applications']
        end
        params do
          requires :id, type: Integer, desc: 'ID of the application. Differs from the `application_id`.'
        end
        route_setting :authorization, permissions: :delete_oauth_application, boundary_type: :user
        delete ':id' do
          application = ::Authn::OauthApplication.find_by_id(params[:id])
          break not_found!('Application') unless application

          authorize! :delete_oauth_application, application

          result = ::Authn::Applications::DestroyService.new(
            current_user,
            request,
            application
          ).execute

          if result.destroyed?
            no_content!
          else
            render_validation_error!(result)
          end
        end

        desc 'Update an application' do
          detail 'Updates an existing application owned by the authenticated user.'
          success Entities::Application
          tags ['applications']
        end
        params do
          requires :id, type: Integer, desc: 'ID of the application. Differs from the `application_id`.'
          optional :name, type: String, desc: 'Name of the application.'
          optional :scopes, type: String,
            desc: 'Scopes available to the application. Separate multiple scopes with a space.',
            allow_blank: false
        end
        route_setting :authorization, permissions: :update_oauth_application, boundary_type: :user
        put ':id' do
          application = ::Authn::OauthApplication.find_by_id(params[:id])
          break not_found!('Application') unless application

          authorize! :update_oauth_application, application

          update_params = declared_params(include_missing: false).except(:id)

          application = ::Authn::Applications::UpdateService.new(
            current_user,
            request,
            application,
            update_params
          ).execute

          if application.errors.empty?
            present application, with: Entities::Application
          else
            render_validation_error! application
          end
        end
      end
    end
  end
end
