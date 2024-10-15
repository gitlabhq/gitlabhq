# frozen_string_literal: true

module API
  class Organizations < ::API::Base
    feature_category :cell

    before { authenticate! }

    helpers do
      def authorize_organization_creation!
        authorize! :create_organization
      end
    end

    resource :organizations do
      desc 'Create an organization' do
        detail 'This feature was introduced in GitLab 17.5. \
                    This feature is currently in an experimental state. \
                    This feature is behind the `allow_organization_creation` feature flag.'
        success Entities::Organizations::Organization
        tags %w[organizations]
      end
      params do
        requires :name, type: String, desc: 'The name of the organization'
        requires :path, type: String, desc: 'The path of the organization'
        optional :description, type: String, desc: 'The description of the organization'
        optional :avatar, type: ::API::Validations::Types::WorkhorseFile, desc: 'The avatar image for the organization',
          documentation: { type: 'file' }
      end
      post do
        forbidden! unless Feature.enabled?(:allow_organization_creation, current_user)
        check_rate_limit!(:create_organization_api, scope: current_user)
        authorize_organization_creation!

        response = ::Organizations::CreateService
          .new(current_user: current_user, params: declared_params(include_missing: false))
          .execute

        if response.success?
          present response[:organization], with: Entities::Organizations::Organization
        else
          render_api_error!(response.message, :bad_request)
        end
      end
    end
  end
end
