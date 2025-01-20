# frozen_string_literal: true

# PyPI Package Manager Client API
#
# These API endpoints are not meant to be consumed directly by users. They are
# called by the PyPI package manager client when users run commands
# like `pip install` or `twine upload`.
module API
  class PypiPackages < ::API::Base
    helpers ::API::Helpers::PackagesManagerClientsHelpers
    helpers ::API::Helpers::RelatedResourcesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    helpers ::API::Helpers::Packages::DependencyProxyHelpers
    include ::API::Helpers::Packages::BasicAuthHelpers::Constants

    feature_category :package_registry
    urgency :low

    default_format :json

    rescue_from ArgumentError do |e|
      render_api_error!(e.message, 400)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    before do
      require_packages_enabled!
    end

    helpers do
      params :package_download do
        requires :file_identifier, type: String, desc: 'The PyPi package file identifier', file_path: true, documentation: { example: 'my.pypi.package-0.0.1.tar.gz' }
        requires :sha256, type: String, desc: 'The PyPi package sha256 check sum', documentation: { example: '5y57017232013c8ac80647f4ca153k3726f6cba62d055cd747844ed95b3c65ff' }
      end

      params :package_name do
        requires :package_name, type: String, file_path: true, desc: 'The PyPi package name', documentation: { example: 'my.pypi.package' }
      end

      def present_simple_index(group_or_project)
        authorize_read_package!(group_or_project)

        packages = Packages::Pypi::PackagesFinder.new(current_user, group_or_project).execute
        presenter = ::Packages::Pypi::SimpleIndexPresenter.new(packages, group_or_project)

        present_html(presenter.body)
      end

      def present_simple_package(group_or_project)
        authorize_read_package!(group_or_project)
        track_simple_event(group_or_project, 'list_package')

        packages = Packages::Pypi::PackagesFinder.new(current_user, group_or_project, { package_name: params[:package_name] }).execute
        empty_packages = packages.empty?

        redirect_registry_request(
          forward_to_registry: empty_packages,
          package_type: :pypi,
          target: group_or_project,
          package_name: params[:package_name]
        ) do
          not_found!('Package') if empty_packages
          presenter = ::Packages::Pypi::SimplePackageVersionsPresenter.new(packages, group_or_project)

          present_html(presenter.body)
        end
      end

      def track_simple_event(group_or_project, event_name)
        if group_or_project.is_a?(Project)
          project = group_or_project
          namespace = group_or_project.namespace
        else
          project = nil
          namespace = group_or_project
        end

        track_package_event(event_name, :pypi, project: project, namespace: namespace)
      end

      def present_html(content)
        # Adjusts grape output format
        # to be HTML
        content_type 'text/html; charset=utf-8'
        env['api.format'] = :binary

        body content
      end

      def ensure_group!
        find_group(params[:id]) || not_found!
        find_authorized_group!
      end

      def project!(action: :read_package)
        find_project(params[:id]) || not_found!
        authorized_user_project(action: action)
      end

      def validate_fips!
        unprocessable_entity! if declared_params[:sha256_digest].blank?

        true
      end
    end

    params do
      requires :id, types: [Integer, String], desc: 'The ID or full path of the group.'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      after_validation do
        ensure_group!
      end

      namespace ':id/-/packages/pypi' do
        desc 'Download a package file from a group' do
          detail 'This feature was introduced in GitLab 13.12'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[pypi_packages]
        end
        params do
          use :package_download
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, job_token_policies: :read_packages
        get 'files/:sha256/*file_identifier' do
          group = find_authorized_group!
          authorize_read_package!(group)

          filename = "#{params[:file_identifier]}.#{params[:format]}"
          package = Packages::Pypi::PackageFinder.new(current_user, group, { filename: filename, sha256: params[:sha256] }).execute
          package_file = ::Packages::PackageFileFinder.new(package, filename, with_file_name_like: false).execute

          authorize_job_token_policies!(package.project)
          track_package_event('pull_package', :pypi, namespace: group, project: package.project)

          present_package_file!(package_file, supports_direct_download: true)
        end

        desc 'The PyPi Simple Group Index Endpoint' do
          detail 'This feature was introduced in GitLab 15.1'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[pypi_packages]
        end

        # An API entry point but returns an HTML file instead of JSON.
        # PyPi simple API returns a list of packages as a simple HTML file.
        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, skip_job_token_policies: true
        get 'simple', format: :txt do
          present_simple_index(find_authorized_group!)
        end

        desc 'The PyPi Simple Group Package Endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[pypi_packages]
        end

        params do
          use :package_name
        end

        # An API entry point but returns an HTML file instead of JSON.
        # PyPi simple API returns the package descriptor as a simple HTML file.
        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, skip_job_token_policies: true
        get 'simple/*package_name', format: :txt do
          present_simple_package(find_authorized_group!)
        end
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/pypi' do
        desc 'The PyPi package download endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[pypi_packages]
        end

        params do
          use :package_download
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, job_token_policies: :read_packages
        get 'files/:sha256/*file_identifier' do
          project = project!
          authorize_job_token_policies!(project)

          filename = "#{params[:file_identifier]}.#{params[:format]}"
          package = Packages::Pypi::PackageFinder.new(current_user, project, { filename: filename, sha256: params[:sha256] }).execute
          package_file = ::Packages::PackageFileFinder.new(package, filename, with_file_name_like: false).execute

          track_package_event('pull_package', :pypi, project: project, namespace: project.namespace)

          present_package_file!(package_file, supports_direct_download: true)
        end

        desc 'The PyPi Simple Project Index Endpoint' do
          detail 'This feature was introduced in GitLab 15.1'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[pypi_packages]
        end

        # An API entry point but returns an HTML file instead of JSON.
        # PyPi simple API returns a list of packages as a simple HTML file.
        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, job_token_policies: :read_packages
        get 'simple', format: :txt do
          project = project!
          authorize_job_token_policies!(project)
          present_simple_index(project)
        end

        desc 'The PyPi Simple Project Package Endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[pypi_packages]
        end

        params do
          use :package_name
        end

        # An API entry point but returns an HTML file instead of JSON.
        # PyPi simple API returns the package descriptor as a simple HTML file.
        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, job_token_policies: :read_packages
        get 'simple/*package_name', format: :txt do
          project = project!
          authorize_job_token_policies!(project)
          present_simple_package(project)
        end

        desc 'The PyPi Package upload endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
          success code: 201
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' },
            { code: 422, message: 'Unprocessable Entity' }
          ]
          tags %w[pypi_packages]
        end

        params do
          requires :content, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)', documentation: { type: 'file' }
          requires :name, type: String, documentation: { example: 'my.pypi.package' }
          requires :version, type: String, documentation: { example: '1.3.7' }
          optional :requires_python, type: String, documentation: { example: '>=3.7' }
          optional :md5_digest, type: String, documentation: { example: '900150983cd24fb0d6963f7d28e17f72' }
          optional :sha256_digest, type: String, regexp: Gitlab::Regex.sha256_regex, documentation: { example: 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' }
          optional :metadata_version, type: String, documentation: { example: '2.3' }
          optional :author_email, type: String, documentation: { example: 'cschultz@example.com, snoopy@peanuts.com' }
          optional :description, type: String
          optional :description_content_type, type: String,
            documentation: { example: 'text/markdown; charset=UTF-8; variant=GFM' }
          optional :summary, type: String, documentation: { example: 'A module for collecting votes from beagles.' }
          optional :keywords, type: String, documentation: { example: 'dog,puppy,voting,election' }
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, job_token_policies: :admin_packages
        post do
          project = project!(action: :read_project)
          authorize_upload!(project)
          authorize_job_token_policies!(project)

          if project.actual_limits.exceeded?(:pypi_max_file_size, params[:content].size)
            bad_request!('File is too large')
          end

          track_package_event('push_package', :pypi, project: project, namespace: project.namespace)

          validate_fips! if Gitlab::FIPS.enabled?

          service_response = ::Packages::Pypi::CreatePackageService
            .new(project, current_user, declared_params.merge(build: current_authenticated_job))
            .execute

          if service_response.error? && service_response.reason == Packages::Pypi::CreatePackageService::ERROR_RESPONSE_PACKAGE_PROTECTED.reason
            forbidden!(service_response.message)
          end

          bad_request!(service_response.message) if service_response.error?

          created!
        rescue ObjectStorage::RemoteStoreError => e
          Gitlab::ErrorTracking.track_exception(e, extra: { file_name: params[:name], project_id: authorized_user_project.id })

          forbidden!
        end

        desc 'Authorize the PyPi package upload from workhorse' do
          detail 'This feature was introduced in GitLab 12.10'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[pypi_packages]
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        route_setting :authorization, job_token_policies: :admin_packages
        post 'authorize' do
          project = project!(action: :read_project)
          authorize_job_token_policies!(project)
          authorize_workhorse!(
            subject: project,
            has_length: false,
            maximum_size: project.actual_limits.pypi_max_file_size
          )
        end
      end
    end
  end
end
