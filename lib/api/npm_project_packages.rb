# frozen_string_literal: true
module API
  class NpmProjectPackages < ::API::Base
    helpers ::API::Helpers::Packages::Npm

    feature_category :package_registry

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    namespace 'projects/:id/packages/npm' do
      desc 'Download the NPM tarball' do
        detail 'This feature was introduced in GitLab 11.8'
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

        track_package_event('pull_package', package, category: 'API::NpmPackages', project: project, namespace: project.namespace)

        present_carrierwave_file!(package_file.file)
      end

      desc 'Create NPM package' do
        detail 'This feature was introduced in GitLab 11.8'
      end
      params do
        requires :package_name, type: String, desc: 'Package name'
        requires :versions, type: Hash, desc: 'Package version info'
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      put ':package_name', requirements: ::API::Helpers::Packages::Npm::NPM_ENDPOINT_REQUIREMENTS do
        authorize_create_package!(project)

        track_package_event('push_package', :npm, category: 'API::NpmPackages', project: project, user: current_user, namespace: project.namespace)

        created_package = ::Packages::Npm::CreatePackageService
          .new(project, current_user, params.merge(build: current_authenticated_job)).execute

        if created_package[:status] == :error
          render_api_error!(created_package[:message], created_package[:http_status])
        else
          created_package
        end
      end

      include ::API::Concerns::Packages::NpmEndpoints
    end
  end
end
