# frozen_string_literal: true

# PHP composer support (https://getcomposer.org/)
module API
  class ComposerPackages < ::API::Base
    helpers ::API::Helpers::PackagesManagerClientsHelpers
    helpers ::API::Helpers::RelatedResourcesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Packages::BasicAuthHelpers::Constants
    include ::Gitlab::Utils::StrongMemoize

    feature_category :package_registry

    content_type :json, 'application/json'
    default_format :json

    COMPOSER_ENDPOINT_REQUIREMENTS = {
      package_name: API::NO_SLASH_URL_PART_REGEX
    }.freeze

    default_format :json

    rescue_from ArgumentError do |e|
      render_api_error!(e.message, 400)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    rescue_from Packages::Composer::ComposerJsonService::InvalidJson do |e|
      render_api_error!(e.message, 422)
    end

    helpers do
      def packages
        strong_memoize(:packages) do
          packages = ::Packages::Composer::PackagesFinder.new(current_user, user_group).execute

          if params[:package_name].present?
            params[:package_name], params[:sha] = params[:package_name].split('$')

            packages = packages.with_name(params[:package_name])
          end

          packages
        end
      end

      def composer_v2?
        headers['User-Agent'].to_s.include?('Composer/2')
      end

      def presenter
        @presenter ||= ::Packages::Composer::PackagesPresenter.new(user_group, packages, composer_v2?)
      end
    end

    before do
      require_packages_enabled!
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :group, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        user_group
      end

      desc 'Composer packages endpoint at group level'
      route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true, deploy_token_allowed: true
      get ':id/-/packages/composer/packages', urgency: :low do
        presenter.root
      end

      desc 'Composer packages endpoint at group level for packages list'
      params do
        requires :sha, type: String, desc: 'Shasum of current json'
      end
      route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true, deploy_token_allowed: true
      get ':id/-/packages/composer/p/:sha', urgency: :low do
        presenter.provider
      end

      desc 'Composer v2 packages p2 endpoint at group level for package versions metadata'
      params do
        requires :package_name, type: String, file_path: true, desc: 'The Composer package name'
      end
      route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true, deploy_token_allowed: true
      get ':id/-/packages/composer/p2/*package_name', requirements: COMPOSER_ENDPOINT_REQUIREMENTS, file_path: true, urgency: :low do
        not_found! if packages.empty?

        presenter.package_versions
      end

      desc 'Composer packages endpoint at group level for package versions metadata'
      params do
        requires :package_name, type: String, file_path: true, desc: 'The Composer package name'
      end
      route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true, deploy_token_allowed: true
      get ':id/-/packages/composer/*package_name', requirements: COMPOSER_ENDPOINT_REQUIREMENTS, file_path: true, urgency: :low do
        not_found! if packages.empty?
        not_found! if params[:sha].blank?

        presenter.package_versions
      end
    end

    params do
      requires :id, type: Integer, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Composer packages endpoint for registering packages'
      namespace ':id/packages/composer' do
        route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true, deploy_token_allowed: true

        params do
          optional :branch, type: String, desc: 'The name of the branch'
          optional :tag, type: String, desc: 'The name of the tag'
          exactly_one_of :tag, :branch
        end
        post urgency: :low do
          authorize_create_package!(authorized_user_project)

          if params[:branch].present?
            params[:branch] = find_branch!(params[:branch])
          elsif params[:tag].present?
            params[:tag] = find_tag!(params[:tag])
          else
            bad_request!
          end

          ::Packages::Composer::CreatePackageService
            .new(authorized_user_project, current_user, declared_params.merge(build: current_authenticated_job))
            .execute

          track_package_event('push_package', :composer, project: authorized_user_project, user: current_user, namespace: authorized_user_project.namespace)

          created!
        end

        params do
          requires :sha, type: String, desc: 'Shasum of current json'
          requires :package_name, type: String, file_path: true, desc: 'The Composer package name'
        end
        route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true, deploy_token_allowed: true
        get 'archives/*package_name', urgency: :default do
          project = authorized_user_project(action: :read_package)

          package = project
            .packages
            .composer
            .with_name(params[:package_name])
            .with_composer_target(params[:sha])
            .first
          metadata = package&.composer_metadatum

          not_found! unless metadata

          track_package_event('pull_package', :composer, project: project, namespace: project.namespace)
          package.touch_last_downloaded_at

          send_git_archive project.repository, ref: metadata.target_sha, format: 'zip', append_sha: true
        end
      end
    end
  end
end
