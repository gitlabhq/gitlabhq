# frozen_string_literal: true

module Packages
  module FinderHelper
    extend ActiveSupport::Concern

    InvalidPackageTypeError = Class.new(StandardError)
    InvalidStatusError = Class.new(StandardError)

    private

    def packages_for_project(project)
      packages_class.for_projects(project).installable
    end

    # /!\ This function doesn't check user permissions
    # at the package level.
    def packages_for(user, within_group:)
      return packages_class.none unless within_group
      return packages_class.none unless Ability.allowed?(user, :read_group, within_group)

      projects = if user.is_a?(DeployToken)
                   user.accessible_projects
                 else
                   within_group.all_projects
                 end

      packages_class.for_projects(projects).installable
    end

    def packages_visible_to_user(user, within_group:, with_package_registry_enabled: false)
      return packages_class.none unless within_group
      return packages_class.none unless Ability.allowed?(user, :read_group, within_group)

      projects = projects_visible_to_reporters(user, within_group: within_group)
      projects = projects.with_package_registry_enabled if with_package_registry_enabled

      packages_class.for_projects(projects.select(:id)).installable
    end

    def packages_visible_to_user_including_public_registries(user, within_group:)
      projects = projects_visible_to_user_including_public_registries(user, within_group: within_group)

      packages_class.for_projects(projects.select(:id)).installable
    end

    def projects_visible_to_user(user, within_group:)
      return ::Project.none unless within_group
      return ::Project.none unless Ability.allowed?(user, :read_group, within_group)

      projects_visible_to_reporters(user, within_group: within_group)
    end

    def projects_visible_to_user_including_public_registries(user, within_group:)
      return ::Project.none unless within_group

      return ::Project.none unless Ability.allowed?(user, :read_package_within_public_registries,
        within_group.packages_policy_subject)

      projects_visible_to_reporters(user, within_group: within_group, within_public_package_registry: true)
    end

    def projects_visible_to_reporters(user, within_group:, within_public_package_registry: false)
      return user.accessible_projects if user.is_a?(DeployToken)

      access = if Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, within_group.root_ancestor)
                 ::Gitlab::Access::GUEST
               else
                 ::Gitlab::Access::REPORTER
               end

      return within_group.all_projects.public_or_visible_to_user(user, access) unless within_public_package_registry

      ::Project
        .public_or_visible_to_user(user, access)
        .or(::Project.with_public_package_registry)
        .in_namespace(within_group.self_and_descendants)
    end

    def package_type
      params[:package_type].presence
    end

    def filter_by_package_type(packages)
      return packages.without_package_type(:terraform_module) unless package_type
      raise InvalidPackageTypeError unless ::Packages::Package.package_types.key?(package_type)

      packages.with_package_type(package_type)
    end

    def filter_by_package_name(packages)
      return packages unless params[:package_name].present?

      packages.search_by_name(params[:package_name])
    end

    def filter_by_exact_package_name(packages)
      return packages unless params[:package_name].present?

      packages.with_name(params[:package_name])
    end

    def filter_by_package_version(packages)
      return packages unless params[:package_version].present?

      packages.with_version(params[:package_version])
    end

    def filter_with_version(packages)
      return packages if params[:include_versionless].present?

      packages.has_version
    end

    def filter_by_status(packages)
      return packages.displayable unless params[:status].present?
      raise InvalidStatusError unless Package.statuses.key?(params[:status])

      packages.with_status(params[:status])
    end

    def packages_class
      ::Packages::Package
    end
  end
end
