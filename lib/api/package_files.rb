# frozen_string_literal: true

module API
  class PackageFiles < ::API::Base
    include PaginationParams

    before do
      authorize_packages_access!(user_project)
    end

    PACKAGE_FILES_TAGS = %w[package_files].freeze

    feature_category :package_registry
    urgency :low

    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::Npm

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project'
      requires :package_id, type: Integer, desc: 'ID of a package'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List package files' do
        detail 'Get a list of package files of a single package'
        success ::API::Entities::PackageFile
        is_array true
        tags PACKAGE_FILES_TAGS
      end
      params do
        use :pagination
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_packages
      get ':id/packages/:package_id/package_files' do
        package = ::Packages::PackageFinder
          .new(user_project, params[:package_id]).execute

        package_files = package.installable_package_files
                               .preload_pipelines.order_id_asc

        present paginate(package_files), with: ::API::Entities::PackageFile
      end

      desc 'Delete a package file' do
        detail 'This feature was introduced in GitLab 13.12'
        success code: 204
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags PACKAGE_FILES_TAGS
      end
      params do
        requires :package_file_id, type: Integer, desc: 'ID of a package file'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :admin_packages
      delete ':id/packages/:package_id/package_files/:package_file_id' do
        authorize_destroy_package!(user_project)

        # We want to make sure the file belongs to the declared package
        # so we look up the package before looking up the file.
        package = ::Packages::PackageFinder
          .new(user_project, params[:package_id]).execute

        not_found! unless package

        package_file = package.installable_package_files
                              .find_by_id(params[:package_file_id])

        not_found! unless package_file

        destroy_conditionally!(package_file) do |package_file|
          package_file.pending_destruction!

          enqueue_sync_metadata_cache_worker(user_project, package.name) if package.npm?
        end
      end
    end
  end
end
