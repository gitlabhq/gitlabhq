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

    helpers do
      include Gitlab::Utils::StrongMemoize

      def package
        ::Packages::PackageFinder.new(user_project, params[:package_id]).execute
      end
      strong_memoize_attr :package

      def package_file
        package.installable_package_files.find_by_id(params[:package_file_id])
      end
      strong_memoize_attr :package_file
    end

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
        optional :order_by,
          type: String,
          values: %w[id created_at file_name],
          default: 'id',
          desc: 'Return package files ordered by `id`, `created_at` or `file_name`'
        optional :sort,
          type: String,
          values: %w[asc desc],
          default: 'asc',
          desc: 'Return package files sorted in `asc` or `desc` order.'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_packages,
        allow_public_access_for_enabled_project_features: :package_registry
      get ':id/packages/:package_id/package_files' do
        package_files = package.installable_package_files
                               .preload_pipelines
                               .order_by(params[:order_by], params[:sort])

        present paginate(package_files), with: ::API::Entities::PackageFile, user: current_user
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
        not_found! unless package

        if Feature.enabled?(:packages_protected_packages_delete, user_project)
          service_response =
            Packages::Protection::CheckRuleExistenceService.for_delete(
              project: user_project,
              current_user: current_user,
              params: { package_name: package.name, package_type: package.package_type }
            ).execute

          forbidden!('Package is deletion protected.') if service_response[:protection_rule_exists?]
        end

        not_found! unless package_file

        destroy_conditionally!(package_file) do |package_file|
          package_file.pending_destruction!

          enqueue_sync_npm_metadata_cache_worker(user_project, package.name) if package.npm?

          if package.helm? && package_file.helm_channel
            ::Packages::Helm::BulkSyncHelmMetadataCacheService.new(
              current_user,
              ::Packages::PackageFile.id_in(package_file.id)
            ).execute
          end
        end
      end

      desc 'Download a package file' do
        detail 'This feature was introduced in GitLab 18.4'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags PACKAGE_FILES_TAGS
      end
      params do
        requires :package_file_id, type: Integer, desc: 'ID of a package file'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_packages,
        allow_public_access_for_enabled_project_features: :package_registry
      get ':id/packages/:package_id/package_files/:package_file_id/download' do
        not_found! unless package && package_file

        track_package_event('pull_package', package.package_type.to_sym, project: user_project,
          namespace: user_project.namespace)

        present_package_file!(package_file)
      end
    end
  end
end
