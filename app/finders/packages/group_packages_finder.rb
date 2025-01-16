# frozen_string_literal: true

module Packages
  class GroupPackagesFinder
    include ::Packages::FinderHelper

    def initialize(
      current_user, group, params = { exclude_subgroups: false,
                                      exact_name: false,
                                      order_by: 'created_at',
                                      sort: 'asc',
                                      packages_class: ::Packages::Package }
    )
      @current_user = current_user
      @group = group
      @params = params
    end

    def execute
      return packages_class.none unless group

      packages_for_group_projects
    end

    private

    attr_reader :current_user, :group, :params

    def packages_for_group_projects(installable_only: false)
      packages = packages_class
        .including_project_namespace_route
        .including_tags
        .for_projects(group_projects_visible_to_current_user.select(:id))
        .sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
      packages = packages.preload_pipelines if preload_pipelines

      packages = filter_with_version(packages)
      packages = filter_by_package_type(packages)
      packages = (params[:exact_name] ? filter_by_exact_package_name(packages) : filter_by_package_name(packages))
      packages = filter_by_package_version(packages)
      installable_only ? packages.installable : filter_by_status(packages)
    end

    def group_projects_visible_to_current_user
      # according to project_policy.rb
      # access to packages is ruled by:
      # - project is public or the current user has access to it with at least the reporter level
      # - project has a public package registry if the within_public_package_registry param is true
      # - the repository feature is available to the current_user
      projects = if current_user.is_a?(DeployToken)
                   current_user.accessible_projects
                 else
                   visible_projects
                     .with_feature_available_for_user(:repository, current_user)
                     .in_namespace(groups)
                 end

      projects = projects.with_package_registry_enabled if params[:with_package_registry_enabled]
      projects
    end

    def visible_projects
      access = if Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, group.root_ancestor)
                 ::Gitlab::Access::GUEST
               else
                 ::Gitlab::Access::REPORTER
               end

      public_or_visible = ::Project.public_or_visible_to_user(current_user, access)

      return public_or_visible.or(with_public_package_registry) if params[:within_public_package_registry]

      public_or_visible
    end

    def with_public_package_registry
      ::ProjectFeature.with_feature_access_level(:package_registry, ::ProjectFeature::PUBLIC)
    end

    def groups
      return [group] if exclude_subgroups?

      group.self_and_descendants
    end

    def exclude_subgroups?
      params[:exclude_subgroups]
    end

    def preload_pipelines
      params.fetch(:preload_pipelines, true)
    end

    def packages_class
      params.fetch(:packages_class, ::Packages::Package)
    end
  end
end
