# frozen_string_literal: true

module API
  class DebianGroupPackages < ::API::Base
    PACKAGE_FILE_REQUIREMENTS = ::API::DebianProjectPackages::PACKAGE_FILE_REQUIREMENTS.merge(
      project_id: %r{[0-9]+}
    ).freeze

    def self.resource_type
      :group
    end

    resource :groups, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
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
        requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the group.'
      end

      namespace ':id/-/packages/debian' do
        include ::API::Concerns::Packages::DebianPackageEndpoints

        # GET groups/:id/-/packages/debian/pool/:distribution/:project_id/:letter/:package_name/:package_version/:file_name
        params do
          requires :project_id, type: Integer, desc: 'ID of the project.'
          use :shared_package_file_params
        end

        desc 'Download Debian package' do
          detail 'This feature was introduced in GitLab 14.2'
          produces %w[application/octet-stream]
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[packages_debian]
        end
        params do
          requires :distribution, type: String, desc: 'Codename or suite of the Debian distribution.'
          requires :letter, type: String, desc: 'Debian classification of the package, either first-letter or lib-first-letter.'
          requires :package_name, type: String, desc: 'Name of the source package.'
          requires :package_version, type: String, desc: 'Version of the source package.'
          requires :file_name, type: String, desc: 'Name of the package file.'
        end

        route_setting :authorization, permissions: :download_debian_package, boundary_type: :group
        get 'pool/:distribution/:project_id/:letter/:package_name/:package_version/:file_name', requirements: PACKAGE_FILE_REQUIREMENTS do
          present_distribution_package_file!(find_project!(params[:project_id]))
        end
      end
    end
  end
end
