# frozen_string_literal: true

module API
  class DebianGroupPackages < ::API::Base
    PACKAGE_FILE_REQUIREMENTS = ::API::DebianProjectPackages::PACKAGE_FILE_REQUIREMENTS.merge(
      project_id: %r{[0-9]+}.freeze
    ).freeze

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        def user_project
          @project ||= find_project!(params[:project_id])
        end

        def project_or_group
          user_group
        end
      end

      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:debian_group_packages, user_group)

        authorize_read_package!(user_group)
      end

      params do
        requires :id, type: String, desc: 'The ID of a group'
      end

      namespace ':id/-/packages/debian' do
        include ::API::Concerns::Packages::DebianPackageEndpoints

        # GET groups/:id/packages/debian/pool/:distribution/:project_id/:letter/:package_name/:package_version/:file_name
        params do
          requires :project_id, type: Integer, desc: 'The Project Id'
          use :shared_package_file_params
        end

        desc 'The package' do
          detail 'This feature was introduced in GitLab 14.2'
        end

        route_setting :authentication, authenticate_non_public: true
        get 'pool/:distribution/:project_id/:letter/:package_name/:package_version/:file_name', requirements: PACKAGE_FILE_REQUIREMENTS do
          present_package_file!
        end
      end
    end
  end
end
