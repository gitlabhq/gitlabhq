# frozen_string_literal: true

module Packages
  class GroupPackagesFinder
    include ::Packages::FinderHelper

    def initialize(current_user, group, params = { exclude_subgroups: false, order_by: 'created_at', sort: 'asc' })
      @current_user = current_user
      @group = group
      @params = params
    end

    def execute
      return ::Packages::Package.none unless group

      packages_for_group_projects
    end

    private

    attr_reader :current_user, :group, :params

    def packages_for_group_projects(installable_only: false)
      packages = ::Packages::Package
        .including_build_info
        .including_project_route
        .including_tags
        .for_projects(group_projects_visible_to_current_user.select(:id))
        .sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")

      packages = filter_with_version(packages)
      packages = filter_by_package_type(packages)
      packages = filter_by_package_name(packages)
      packages = filter_by_package_version(packages)
      installable_only ? packages.installable : filter_by_status(packages)
    end

    def group_projects_visible_to_current_user
      # according to project_policy.rb
      # access to packages is ruled by:
      # - project is public or the current user has access to it with at least the reporter level
      # - the repository feature is available to the current_user
      ::Project
        .in_namespace(groups)
        .public_or_visible_to_user(current_user, Gitlab::Access::REPORTER)
        .with_feature_available_for_user(:repository, current_user)
    end

    def groups
      return [group] if exclude_subgroups?

      group.self_and_descendants
    end

    def exclude_subgroups?
      params[:exclude_subgroups]
    end
  end
end
