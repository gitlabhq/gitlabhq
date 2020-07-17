# frozen_string_literal: true
module API
  class NpmPackages < Grape::API::Instance
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::DependencyProxyHelpers

    NPM_ENDPOINT_REQUIREMENTS = {
      package_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    before do
      require_packages_enabled!
      authenticate_non_get!
    end

    helpers do
      def project_by_package_name
        strong_memoize(:project_by_package_name) do
          ::Packages::Package.npm.with_name(params[:package_name]).first&.project
        end
      end
    end

    desc 'Get all tags for a given an NPM package' do
      detail 'This feature was introduced in GitLab 12.7'
      success ::API::Entities::NpmPackageTag
    end
    params do
      requires :package_name, type: String, desc: 'Package name'
    end
    get 'packages/npm/-/package/*package_name/dist-tags', format: false, requirements: NPM_ENDPOINT_REQUIREMENTS do
      package_name = params[:package_name]

      bad_request!('Package Name') if package_name.blank?

      authorize_read_package!(project_by_package_name)

      packages = ::Packages::Npm::PackageFinder.new(project_by_package_name, package_name)
                                              .execute

      present ::Packages::Npm::PackagePresenter.new(package_name, packages),
              with: ::API::Entities::NpmPackageTag
    end

    params do
      requires :package_name, type: String, desc: 'Package name'
      requires :tag, type: String, desc: "Package dist-tag"
    end
    namespace 'packages/npm/-/package/*package_name/dist-tags/:tag', requirements: NPM_ENDPOINT_REQUIREMENTS do
      desc 'Create or Update the given tag for the given NPM package and version' do
        detail 'This feature was introduced in GitLab 12.7'
      end
      put format: false do
        package_name = params[:package_name]
        version = env['api.request.body']
        tag = params[:tag]

        bad_request!('Package Name') if package_name.blank?
        bad_request!('Version') if version.blank?
        bad_request!('Tag') if tag.blank?

        authorize_create_package!(project_by_package_name)

        package = ::Packages::Npm::PackageFinder
          .new(project_by_package_name, package_name)
          .find_by_version(version)
        not_found!('Package') unless package

        ::Packages::Npm::CreateTagService.new(package, tag).execute

        no_content!
      end

      desc 'Deletes the given tag' do
        detail 'This feature was introduced in GitLab 12.7'
      end
      delete format: false do
        package_name = params[:package_name]
        tag = params[:tag]

        bad_request!('Package Name') if package_name.blank?
        bad_request!('Tag') if tag.blank?

        authorize_destroy_package!(project_by_package_name)

        package_tag = ::Packages::TagsFinder
          .new(project_by_package_name, package_name, package_type: :npm)
          .find_by_name(tag)

        not_found!('Package tag') unless package_tag

        ::Packages::RemoveTagService.new(package_tag).execute

        no_content!
      end
    end

    desc 'NPM registry endpoint at instance level' do
      detail 'This feature was introduced in GitLab 11.8'
    end
    params do
      requires :package_name, type: String, desc: 'Package name'
    end
    route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
    get 'packages/npm/*package_name', format: false, requirements: NPM_ENDPOINT_REQUIREMENTS do
      package_name = params[:package_name]

      redirect_registry_request(project_by_package_name.blank?, :npm, package_name: package_name) do
        authorize_read_package!(project_by_package_name)

        packages = ::Packages::Npm::PackageFinder
          .new(project_by_package_name, package_name).execute

        present ::Packages::Npm::PackagePresenter.new(package_name, packages),
          with: ::API::Entities::NpmPackage
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Download the NPM tarball' do
        detail 'This feature was introduced in GitLab 11.8'
      end
      params do
        requires :package_name, type: String, desc: 'Package name'
        requires :file_name, type: String, desc: 'Package file name'
      end
      route_setting :authentication, job_token_allowed: true, deploy_token_allowed: true
      get ':id/packages/npm/*package_name/-/*file_name', format: false do
        authorize_read_package!(user_project)

        package = user_project.packages.npm
          .by_name_and_file_name(params[:package_name], params[:file_name])

        package_file = ::Packages::PackageFileFinder
          .new(package, params[:file_name]).execute!

        track_event('pull_package')

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
      put ':id/packages/npm/:package_name', requirements: NPM_ENDPOINT_REQUIREMENTS do
        authorize_create_package!(user_project)

        track_event('push_package')

        created_package = ::Packages::Npm::CreatePackageService
          .new(user_project, current_user, params.merge(build: current_authenticated_job)).execute

        if created_package[:status] == :error
          render_api_error!(created_package[:message], created_package[:http_status])
        else
          created_package
        end
      end
    end
  end
end
