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
    include ::API::Helpers::Packages::BasicAuthHelpers::Constants

    feature_category :package_registry

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
        requires :file_identifier, type: String, desc: 'The PyPi package file identifier', file_path: true
        requires :sha256, type: String, desc: 'The PyPi package sha256 check sum'
      end

      params :package_name do
        requires :package_name, type: String, file_path: true, desc: 'The PyPi package name'
      end
    end

    params do
      requires :id, type: Integer, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      after_validation do
        unauthorized_user_group!
      end

      namespace ':id/-/packages/pypi' do
        params do
          use :package_download
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        get 'files/:sha256/*file_identifier' do
          group = unauthorized_user_group!

          filename = "#{params[:file_identifier]}.#{params[:format]}"
          package = Packages::Pypi::PackageFinder.new(current_user, group, { filename: filename, sha256: params[:sha256] }).execute
          package_file = ::Packages::PackageFileFinder.new(package, filename, with_file_name_like: false).execute

          track_package_event('pull_package', :pypi)

          present_carrierwave_file!(package_file.file, supports_direct_download: true)
        end

        desc 'The PyPi Simple Endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
        end

        params do
          use :package_name
        end

        # An Api entry point but returns an HTML file instead of JSON.
        # PyPi simple API returns the package descriptor as a simple HTML file.
        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        get 'simple/*package_name', format: :txt do
          group = find_authorized_group!
          authorize_read_package!(group)

          track_package_event('list_package', :pypi)

          packages = Packages::Pypi::PackagesFinder.new(current_user, group, { package_name: params[:package_name] }).execute!
          presenter = ::Packages::Pypi::PackagePresenter.new(packages, group)

          # Adjusts grape output format
          # to be HTML
          content_type "text/html; charset=utf-8"
          env['api.format'] = :binary

          body presenter.body
        end
      end
    end

    params do
      requires :id, type: Integer, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        unauthorized_user_project!
      end

      namespace ':id/packages/pypi' do
        desc 'The PyPi package download endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
        end

        params do
          use :package_download
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        get 'files/:sha256/*file_identifier' do
          project = unauthorized_user_project!

          filename = "#{params[:file_identifier]}.#{params[:format]}"
          package = Packages::Pypi::PackageFinder.new(current_user, project, { filename: filename, sha256: params[:sha256] }).execute
          package_file = ::Packages::PackageFileFinder.new(package, filename, with_file_name_like: false).execute

          track_package_event('pull_package', :pypi, project: project, namespace: project.namespace)

          present_carrierwave_file!(package_file.file, supports_direct_download: true)
        end

        desc 'The PyPi Simple Endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
        end

        params do
          use :package_name
        end

        # An Api entry point but returns an HTML file instead of JSON.
        # PyPi simple API returns the package descriptor as a simple HTML file.
        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        get 'simple/*package_name', format: :txt do
          authorize_read_package!(authorized_user_project)

          track_package_event('list_package', :pypi, project: authorized_user_project, namespace: authorized_user_project.namespace)

          packages = Packages::Pypi::PackagesFinder.new(current_user, authorized_user_project, { package_name: params[:package_name] }).execute!
          presenter = ::Packages::Pypi::PackagePresenter.new(packages, authorized_user_project)

          # Adjusts grape output format
          # to be HTML
          content_type "text/html; charset=utf-8"
          env['api.format'] = :binary

          body presenter.body
        end

        desc 'The PyPi Package upload endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
        end

        params do
          requires :content, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)'
          requires :requires_python, type: String
          requires :name, type: String
          requires :version, type: String
          optional :md5_digest, type: String
          optional :sha256_digest, type: String
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        post do
          authorize_upload!(authorized_user_project)
          bad_request!('File is too large') if authorized_user_project.actual_limits.exceeded?(:pypi_max_file_size, params[:content].size)

          track_package_event('push_package', :pypi, project: authorized_user_project, user: current_user, namespace: authorized_user_project.namespace)

          ::Packages::Pypi::CreatePackageService
            .new(authorized_user_project, current_user, declared_params.merge(build: current_authenticated_job))
            .execute

          created!
        rescue ObjectStorage::RemoteStoreError => e
          Gitlab::ErrorTracking.track_exception(e, extra: { file_name: params[:name], project_id: authorized_user_project.id })

          forbidden!
        end

        route_setting :authentication, deploy_token_allowed: true, basic_auth_personal_access_token: true, job_token_allowed: :basic_auth
        post 'authorize' do
          authorize_workhorse!(
            subject: authorized_user_project,
            has_length: false,
            maximum_size: authorized_user_project.actual_limits.pypi_max_file_size
          )
        end
      end
    end
  end
end
