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
          packages = ::Packages::Composer::PackagesFinder.new(current_user, find_authorized_group!).execute

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
        @presenter ||= ::Packages::Composer::PackagesPresenter.new(find_authorized_group!, packages, composer_v2?)
      end
    end

    before do
      require_packages_enabled!
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of a group'
    end

    resource :group, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      after_validation do
        find_authorized_group!
      end

      desc 'Composer packages endpoint at group level' do
        detail 'This feature was introduced in GitLab 13.1'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[composer_packages]
      end
      route_setting :authentication, job_token_allowed: :basic_auth, basic_auth_personal_access_token: true, deploy_token_allowed: true
      route_setting :authorization, skip_job_token_policies: true
      get ':id/-/packages/composer/packages', urgency: :low do
        presenter.root
      end

      desc 'Composer packages endpoint at group level for packages list' do
        detail 'This feature was introduced in GitLab 13.1'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[composer_packages]
      end
      params do
        requires :sha, type: String, desc: 'Shasum of current json', documentation: { example: '673594f85a55fe3c0eb45df7bd2fa9d95a1601ab' }
      end
      route_setting :authentication, job_token_allowed: :basic_auth, basic_auth_personal_access_token: true, deploy_token_allowed: true
      route_setting :authorization, skip_job_token_policies: true
      get ':id/-/packages/composer/p/:sha', urgency: :low do
        presenter.provider
      end

      desc 'Composer v2 packages p2 endpoint at group level for package versions metadata' do
        detail 'This feature was introduced in GitLab 13.1'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[composer_packages]
      end
      params do
        requires :package_name, type: String, file_path: true, desc: 'The Composer package name', documentation: { example: 'my-composer-package' }
      end
      route_setting :authentication, job_token_allowed: :basic_auth, basic_auth_personal_access_token: true, deploy_token_allowed: true
      route_setting :authorization, skip_job_token_policies: true
      get ':id/-/packages/composer/p2/*package_name', requirements: COMPOSER_ENDPOINT_REQUIREMENTS, file_path: true, urgency: :low do
        not_found! if packages.empty?

        presenter.package_versions
      end

      desc 'Composer packages endpoint at group level for package versions metadata' do
        detail 'This feature was introduced in GitLab 12.1'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[composer_packages]
      end
      params do
        requires :package_name, type: String, file_path: true, desc: 'The Composer package name', documentation: { example: 'my-composer-package' }
      end
      route_setting :authentication, job_token_allowed: :basic_auth, basic_auth_personal_access_token: true, deploy_token_allowed: true
      route_setting :authorization, skip_job_token_policies: true
      get ':id/-/packages/composer/*package_name', requirements: COMPOSER_ENDPOINT_REQUIREMENTS, file_path: true, urgency: :low do
        not_found! if packages.empty?
        not_found! if params[:sha].blank?

        presenter.package_versions
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/composer' do
        route_setting :authentication, job_token_allowed: true, basic_auth_personal_access_token: true, deploy_token_allowed: true
        route_setting :authorization, job_token_policies: :admin_packages

        desc 'Composer packages endpoint for registering packages' do
          detail 'This feature was introduced in GitLab 13.1'
          success code: 201
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[composer_packages]
        end
        params do
          optional :branch, type: String, desc: 'The name of the branch', documentation: { example: 'release' }
          optional :tag, type: String, desc: 'The name of the tag', documentation: { example: 'v1.0.0' }
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

          track_package_event('push_package', :composer, project: authorized_user_project, namespace: authorized_user_project.namespace)

          created!
        end

        desc 'Composer package endpoint to download a package archive' do
          detail 'This feature was introduced in GitLab 13.1'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' }
          ]
          tags %w[composer_packages]
        end
        params do
          requires :sha, type: String, desc: 'Shasum of current json', documentation: { example: '673594f85a55fe3c0eb45df7bd2fa9d95a1601ab' }
          requires :package_name, type: String, file_path: true, desc: 'The Composer package name', documentation: { example: 'my-composer-package' }
        end
        route_setting :authentication, job_token_allowed: :basic_auth, basic_auth_personal_access_token: true, deploy_token_allowed: true
        route_setting :authorization, job_token_policies: :read_packages
        get 'archives/*package_name', urgency: :default do
          project = authorized_user_project(action: :read_package)
          authorize_job_token_policies!(project)

          package = ::Packages::Composer::Package
            .for_projects(project)
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
