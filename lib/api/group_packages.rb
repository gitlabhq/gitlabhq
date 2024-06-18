# frozen_string_literal: true

module API
  class GroupPackages < ::API::Base
    include PaginationParams

    before do
      authorize_packages_access!(user_group)
    end

    feature_category :package_registry
    urgency :low

    helpers ::API::Helpers::PackagesHelpers

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the group'
      optional :exclude_subgroups, type: Boolean, default: false, desc: 'Determines if subgroups should be excluded'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List packages within a group' do
        detail 'Get a list of project packages at the group level. This feature was introduced in GitLab 12.5'
        success ::API::Entities::Package
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Group Not Found' }
        ]
        is_array true
        tags %w[group_packages]
      end
      params do
        use :pagination
        optional :order_by,
          type: String,
          values: %w[created_at name version type project_path],
          default: 'created_at',
          desc: 'Return packages ordered by `created_at`, `name`, `version` or `type` fields.'
        optional :sort,
          type: String,
          values: %w[asc desc],
          default: 'asc',
          desc: 'Return packages sorted in `asc` or `desc` order.'
        optional :package_type,
          type: String,
          values: Packages::Package.package_types.keys,
          desc: 'Return packages of a certain type'
        optional :package_name,
          type: String,
          desc: 'Return packages with this name'
        optional :package_version,
          type: String,
          desc: 'Return packages with this version'
        optional :include_versionless,
          type: Boolean,
          desc: 'Returns packages without a version'
        optional :status,
          type: String,
          values: Packages::Package.statuses.keys,
          desc: 'Return packages with specified status'
      end
      get ':id/packages' do
        packages = Packages::GroupPackagesFinder.new(
          current_user,
          user_group,
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
