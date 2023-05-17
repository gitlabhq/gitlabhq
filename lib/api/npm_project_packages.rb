# frozen_string_literal: true
module API
  class NpmProjectPackages < ::API::Base
    helpers ::API::Helpers::Packages::Npm

    feature_category :package_registry
    urgency :low

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    namespace 'projects/:id/packages/npm' do
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
      get '*package_name/-/*file_name', format: false do
        authorize_read_package!(project)

        package = project.packages.npm
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
      put ':package_name', requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
        if headers['Npm-Command'] == 'deprecate'
          authorize_destroy_package!(project)

          ::Packages::Npm::DeprecatePackageService.new(project, declared(params)).execute(async: true)
        else
          authorize_create_package!(project)

          created_package = ::Packages::Npm::CreatePackageService
            .new(project, current_user, params.merge(build: current_authenticated_job)).execute

          if created_package[:status] == :error
            render_api_error!(created_package[:message], created_package[:http_status])
          else
            track_package_event('push_package', :npm, category: 'API::NpmPackages', project: project, namespace: project.namespace)
            created_package
          end
        end
      end

      include ::API::Concerns::Packages::NpmEndpoints
    end
  end
end
