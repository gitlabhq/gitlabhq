# frozen_string_literal: true

module API
  class GroupPackages < ::API::Base
    include PaginationParams

    before do
      authorize_packages_access!(user_group, :read_group)
    end

    feature_category :package_registry
    urgency :low

    helpers ::API::Helpers::PackagesHelpers

    helpers do
      def projects
        ::Packages::ProjectsFinder
          .new(
            current_user: current_user,
            group: user_group,
            params: declared(params).slice(:exclude_subgroups).merge(with_package_registry_enabled: true)
          )
          .execute
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the group.'
      optional :exclude_subgroups, type: Boolean, default: false, desc: 'If `true`, excludes packages from subgroup ' \
                                                                    'projects.'
    end
    resource :groups, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all packages for a group' do
        detail 'Lists all packages for a specified group. When accessed without authentication, only packages of ' \
          'public projects are returned. By default, packages with `default`, `deprecated`, and `error` status are ' \
          'returned. Use the `status` parameter to view other packages.'
        success ::API::Entities::Package
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Group Not Found' }
        ]
        is_array true
        tags %w[packages]
      end
      params do
        use :pagination
        optional :order_by,
          type: String,
          values: %w[created_at name version type project_path],
          default: 'created_at',
          desc: 'Sort results by the specified field.'
        optional :sort,
          type: String,
          values: %w[asc desc],
          default: 'asc',
          desc: 'Sort results in ascending or descending order.'
        optional :package_type,
          type: String,
          values: Packages::Package.package_types.keys,
          desc: 'Filter packages by type.'
        optional :package_name,
          type: String,
          desc: 'Filter packages by name, using a fuzzy search.'
        optional :package_version,
          type: String,
          desc: 'Filter packages by version. When used together with `include_versionless`, versionless packages are ' \
            'not returned.'
        optional :include_versionless,
          type: Boolean,
          desc: 'If `true`, includes versionless packages in the response.'
        optional :status,
          type: String,
          values: Packages::Package.statuses.keys,
          desc: 'Filter packages by status.'
      end
      route_setting :authorization, permissions: :read_package, boundary_type: :group
      get ':id/packages' do
        packages = ::Packages::PackagesFinder.new(
          projects,
          declared(params).slice(
            :exclude_subgroups, :order_by, :sort, :package_type, :package_name,
            :package_version, :include_versionless, :status
          )
        ).execute

        present paginate(packages), with: ::API::Entities::Package, user: current_user, group: true,
          namespace: user_group
      end
    end
  end
end
