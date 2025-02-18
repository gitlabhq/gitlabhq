# frozen_string_literal: true
module API
  class NpmProjectPackages < ::API::Base
    ERROR_REASON_TO_HTTP_STATUS_MAPPTING = {
      ::Packages::Npm::CreatePackageService::ERROR_REASON_INVALID_PARAMETER => 400,
      ::Packages::Npm::CreatePackageService::ERROR_REASON_PACKAGE_EXISTS => 403,
      ::Packages::Npm::CreatePackageService::ERROR_REASON_PACKAGE_LEASE_TAKEN => 400,
      ::Packages::Npm::CreatePackageService::ERROR_REASON_PACKAGE_PROTECTED => 403,
      ::Packages::Npm::CreatePackageService::ERROR_REASON_UNAUTHORIZED => 403
    }.freeze

    helpers ::API::Helpers::Packages::Npm
    helpers ::API::Helpers::Packages::DependencyProxyHelpers

    feature_category :package_registry
    urgency :low

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_structured_api_error!({ message: e.message, error: e.message }, 400)
    end

    helpers do
      include Gitlab::Utils::StrongMemoize

      def error_reason_to_http_status(reason)
        ERROR_REASON_TO_HTTP_STATUS_MAPPTING.fetch(reason, 400)
      end

      def metadata_cache
        ::Packages::Npm::MetadataCache
          .find_by_package_name_and_project_id(params[:package_name], project.id)
      end
      strong_memoize_attr :metadata_cache

      def project
        user_project(action: :read_package)
      end

      def project_id_or_nil
        params[:id]
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    namespace 'projects/:id/packages/npm' do
      include ::API::Concerns::Packages::NpmEndpoints

      desc 'Download the NPM tarball' do
        detail 'This feature was introduced in GitLab 11.8'
        success code: 200
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[npm_packages]
      end
      params do
        requires :package_name, type: String, desc: 'Package name'
        requires :file_name, type: String, desc: 'Package file name'
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      route_setting :authorization, job_token_policies: :read_packages
      get '*package_name/-/*file_name', format: false do
        authorize_read_package!(project)

        package = ::Packages::Npm::Package
                    .for_projects(project)
                    .by_name_and_file_name(params[:package_name], params[:file_name])

        not_found!('Package') unless package

        package_file = ::Packages::PackageFileFinder
          .new(package, params[:file_name]).execute!

        track_package_event('pull_package', :npm, category: 'API::NpmPackages', project: project, namespace: project.namespace)

        present_package_file!(package_file)
      end

      desc 'Create or deprecate NPM package' do
        detail 'Create was introduced in GitLab 11.8 & deprecate suppport was added in 16.0'
        success code: 200
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[npm_packages]
      end
      params do
        requires :package_name, type: String, desc: 'Package name'
        requires :versions, type: Hash, desc: 'Package version info'
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      route_setting :authorization, job_token_policies: :admin_packages
      put ':package_name', requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
        if headers['Npm-Command'] == 'deprecate'
          authorize_destroy_package!(project)

          response = ::Packages::Npm::EnqueueDeprecatePackageWorkerService.new(project, nil, declared(params).to_hash).execute

          if response.error? && response.reason == :no_versions_to_deprecate
            bad_request_missing_attribute!('package versions to deprecate')
          end
        else
          authorize_create_package!(project)

          service_response = ::Packages::Npm::CreatePackageService
            .new(project, current_user, params.merge(build: current_authenticated_job)).execute

          if service_response.error?
            render_structured_api_error!({ message: service_response.message, error: service_response.message }, error_reason_to_http_status(service_response.reason))
          end

          track_package_event('push_package', :npm, category: 'API::NpmPackages', project: project, namespace: project.namespace)
          service_response[:package]
        end
      end

      # Caution: This is a globbing wildcard for GET requests
      # Do not put other GET routes below this one
      desc 'NPM registry metadata endpoint' do
        detail 'This feature was introduced in GitLab 11.8'
        success [
          { code: 200, model: ::API::Entities::NpmPackage, message: 'Ok' },
          { code: 302, message: 'Found (redirect)' }
        ]
        failure [
          { code: 400, message: 'Bad Request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[npm_packages]
      end
      params do
        use :package_name
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true,
        authenticate_non_public: true
      route_setting :authorization, job_token_policies: :read_packages
      get '*package_name', format: false, requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
        package_name = declared_params[:package_name]
        packages = ::Packages::Npm::PackageFinder.new(project: project_or_nil, params: { package_name: package_name }).execute

        # In order to redirect a request, packages should not exist (without taking the user into account).
        redirect_request = project_or_nil.blank? || packages.empty?

        redirect_registry_request(
          forward_to_registry: redirect_request,
          package_type: :npm,
          target: project_or_nil,
          package_name: package_name
        ) do
          authorize_read_package!(project)

          not_found!('Packages') if packages.empty?

          if metadata_cache&.file&.exists?
            metadata_cache.touch_last_downloaded_at
            present_carrierwave_file!(metadata_cache.file)

            break
          end

          enqueue_sync_metadata_cache_worker(project, package_name)

          metadata = generate_metadata_service(packages).execute.payload
          present metadata, with: ::API::Entities::NpmPackage
        end
      end
    end
  end
end
