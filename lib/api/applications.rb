# frozen_string_literal: true

module API
  # External applications API
  class Applications < ::API::Base
    helpers ::API::Helpers::Authz::GranularScopesHelpers

    # DeclareService reasons that are not plain input errors. Every other reason
    # (:access_not_allowed, :duplicate, :invalid, :no_resources, :dynamic_application)
    # is a 400, matching how this endpoint already reports model validation errors.
    DECLARE_GRANULAR_SCOPES_ERROR_STATUS = {
      feature_disabled: :not_found,
      resource_not_allowed: :not_found,
      forbidden: :forbidden
    }.freeze

    before do
      authenticated_as_admin!
    end

    feature_category :system_access

    resource :applications do
      desc 'Create a new application' do
        detail 'This feature was introduced in GitLab 10.5. The granular_scopes parameter requires the ' \
          'granular_oauth_tokens feature flag.'
        success code: 200, model: Entities::ApplicationWithSecret
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
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
          desc: 'If `true`, the application can securely store client credentials, such as the client secret. ' \
            'Non-confidential applications (such as native mobile apps and Single Page Apps) might expose client ' \
            'credentials.'
        use :granular_scope_params
      end
      route_setting :authorization, permissions: :create_oauth_application, boundary_type: :instance,
        assignable_when: [:admin]
      post do
        # granular_scopes is nil when not sent and [] when sent empty, which declares an empty set
        service = ::Applications::CreateService.new(current_user, request,
          declared_params(include_missing: false).merge(organization: Current.organization),
          access_token: access_token)
        application = service.execute
        declaration = service.declaration

        if declaration&.error?
          render_api_error!(declaration.message,
            DECLARE_GRANULAR_SCOPES_ERROR_STATUS.fetch(declaration.reason, :bad_request))
        end

        render_validation_error!(application) unless application.persisted?

        ActiveRecord::Associations::Preloader.new(
          records: [application], associations: { granular_scopes: :namespace }
        ).call

        present application, with: Entities::ApplicationWithSecret,
          with_granular_scopes: Feature.enabled?(:granular_oauth_tokens, current_user),
          project_ids_by_namespace_id: project_ids_by_namespace_id_for([application]),
          warnings: declaration&.payload&.dig(:warnings)
      end

      desc 'Get applications' do
        detail 'List all registered applications'
        success Entities::Application
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        tags ['applications']
      end
      route_setting :authorization, permissions: :read_oauth_application, boundary_type: :instance,
        assignable_when: [:admin]
      get do
        applications = ApplicationsFinder.new.execute
        present applications, with: Entities::Application
      end

      desc 'Delete an application' do
        detail 'Delete a specific application'
        success code: 204
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags ['applications']
      end
      params do
        requires :id, type: Integer, desc: 'ID of the application. Not the `application_id`, which is the OAuth ' \
                                       'client ID.'
      end
      route_setting :authorization, permissions: :delete_oauth_application, boundary_type: :instance,
        assignable_when: [:admin]
      delete ':id' do
        application = ApplicationsFinder.new(params).execute
        break not_found!('Application') unless application

        application.destroy

        no_content!
      end

      desc 'Renew an application secret' do
        detail 'Renew the secret of a specific application'
        success code: 200, model: Entities::ApplicationWithSecret
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags ['applications']
      end
      params do
        requires :id, type: Integer, desc: 'ID of the application. Not the `application_id`, which is the OAuth ' \
                                       'client ID.'
      end
      route_setting :authorization, permissions: :renew_secret_oauth_application, boundary_type: :instance,
        assignable_when: [:admin]
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
