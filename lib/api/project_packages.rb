# frozen_string_literal: true

module API
  class ProjectPackages < ::API::Base
    include Gitlab::Utils::StrongMemoize
    include PaginationParams

    before do
      authorize_packages_access!(user_project)
    end

    feature_category :package_registry
    urgency :low

    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::Npm
    helpers do
      def package
        strong_memoize(:package) do # rubocop:disable Gitlab/StrongMemoizeAttr
          ::Packages::PackageFinder.new(user_project, declared_params[:package_id]).execute
        end
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project packages' do
        detail 'This feature was introduced in GitLab 11.8'
        success code: 200, model: ::API::Entities::Package
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Project Not Found' }
        ]
        is_array true
        tags %w[project_packages]
      end
      params do
        use :pagination
        optional :order_by, type: String, values: %w[created_at name version type], default: 'created_at',
          desc: 'Return packages ordered by `created_at`, `name`, `version` or `type` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'asc',
          desc: 'Return packages sorted in `asc` or `desc` order.'
        optional :package_type, type: String, values: Packages::Package.package_types.keys,
          desc: 'Return packages of a certain type'
        optional :package_name, type: String,
          desc: 'Return packages with this name'
        optional :package_version, type: String,
          desc: 'Return packages with this version'
        optional :include_versionless, type: Boolean,
          desc: 'Returns packages without a version'
        optional :status, type: String, values: Packages::Package.statuses.keys,
          desc: 'Return packages with specified status'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_packages
      get ':id/packages' do
        packages = ::Packages::PackagesFinder.new(
          user_project,
          declared_params.slice(:order_by, :sort, :package_type, :package_name, :package_version, :include_versionless, :status)
        ).execute

        present paginate(packages), with: ::API::Entities::Package, user: current_user, namespace: user_project.namespace
      end

      desc 'Get a single project package' do
        detail 'This feature was introduced in GitLab 11.9'
        success code: 200, model: ::API::Entities::Package
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[project_packages]
      end
      params do
        requires :package_id, type: Integer, desc: 'The ID of a package'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_packages
      get ':id/packages/:package_id' do
        render_api_error!('Package not found', 404) unless package.detailed_info?

        present package, with: ::API::Entities::Package, user: current_user, namespace: user_project.namespace
      end

      desc 'Get the pipelines for a single project package' do
        detail 'This feature was introduced in GitLab 16.1'
        success code: 200, model: ::API::Entities::Package::Pipeline
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[project_packages]
      end
      params do
        use :pagination
        requires :package_id, type: Integer, desc: 'The ID of a package'
        optional :cursor, type: String, desc: 'Cursor for obtaining the next set of records'
        # Overrides the original definition to add the `values: 1..20` restriction
        optional :per_page, type: Integer, default: 20,
          desc: 'Number of items per page', documentation: { example: 20 },
          values: 1..20
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :read_packages
      get ':id/packages/:package_id/pipelines' do
        not_found!('Package not found') unless package.detailed_info?

        params[:pagination] = 'keyset' # keyset is the only available pagination
        pipelines = paginate_with_strategies(
          package.build_infos.without_empty_pipelines,
          paginator_params: { per_page: declared_params[:per_page], cursor: declared_params[:cursor] }
        ) do |results|
          ::Packages::PipelinesFinder.new(results.map(&:pipeline_id)).execute
        end

        present pipelines, with: ::API::Entities::Package::Pipeline, user: current_user
      end

      desc 'Delete a project package' do
        detail 'This feature was introduced in GitLab 11.9'
        success code: 204
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags %w[project_packages]
      end
      params do
        requires :package_id, type: Integer, desc: 'The ID of a package'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, job_token_policies: :admin_packages
      delete ':id/packages/:package_id' do
        authorize_destroy_package!(user_project)

        destroy_conditionally!(package) do |package|
          ::Packages::MarkPackageForDestructionService.new(container: package, current_user: current_user).execute
        end
      end
    end
  end
end
