# frozen_string_literal: true

module API
  class DebianGroupPackages < ::API::Base
    PACKAGE_FILE_REQUIREMENTS = ::API::DebianProjectPackages::PACKAGE_FILE_REQUIREMENTS.merge(
      project_id: %r{[0-9]+}
    ).freeze

    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      helpers do
        def project_or_group
          find_authorized_group!
        end
      end

      after_validation do
        require_packages_enabled!

        not_found! unless ::Feature.enabled?(:debian_group_packages, project_or_group)

        authorize_read_package!(project_or_group)
      end

      params do
        requires :id, types: [String, Integer], desc: 'The group ID or full group path.'
      end

      namespace ':id/-/packages/debian' do
        include ::API::Concerns::Packages::DebianPackageEndpoints

        # GET groups/:id/-/packages/debian/pool/:distribution/:project_id/:letter/:package_name/:package_version/:file_name
        params do
          requires :project_id, type: Integer, desc: 'The Project Id'
          use :shared_package_file_params
        end

        desc 'Download Debian package' do
          detail 'This feature was introduced in GitLab 14.2'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[debian_packages]
        end

        get 'pool/:distribution/:project_id/:letter/:package_name/:package_version/:file_name', requirements: PACKAGE_FILE_REQUIREMENTS do
          present_distribution_package_file!(find_project!(params[:project_id]))
        end
      end
    end
  end
end
