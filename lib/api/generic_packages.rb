# frozen_string_literal: true

module API
  class GenericPackages < Grape::API::Instance
    before do
      require_packages_enabled!
      authenticate!

      require_generic_packages_available!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      route_setting :authentication, job_token_allowed: true

      namespace ':id/packages/generic' do
        get 'ping' do
          :pong
        end
      end
    end

    helpers do
      include ::API::Helpers::PackagesHelpers

      def require_generic_packages_available!
        not_found! unless Feature.enabled?(:generic_packages, user_project)
      end
    end
  end
end
