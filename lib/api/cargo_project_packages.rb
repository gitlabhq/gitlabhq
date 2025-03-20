# frozen_string_literal: true

module API
  class CargoProjectPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Authentication

    feature_category :package_registry
    urgency :low
    default_format :json

    authenticate_with do |accept|
      accept.token_types(:personal_access_token, :deploy_token, :job_token)
            .sent_through(:http_bearer_token)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        def project
          authorized_user_project(action: :read_package)
        end

        def cargo_registry_url
          URI.join(
            Gitlab.config.gitlab.url,
            File.join(
              api_v4_projects_packages_path(id: project.id),
              "/packages/cargo"
            )
          )
        end
      end

      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:package_registry_cargo_support, project)

        authorize_read_package!(project)
      end

      namespace ':id/packages/cargo' do
        desc 'Get config.json' do
          detail 'This will be used by cargo for further requests'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' }
          ]
          tags %w[cargo_packages]
        end

        get 'config.json' do
          {
            "dl" => cargo_registry_url,
            "api" => cargo_registry_url,
            "auth-required" => !project.public?
          }
        end
      end
    end
  end
end
