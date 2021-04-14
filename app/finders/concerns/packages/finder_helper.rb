# frozen_string_literal: true

module Packages
  module FinderHelper
    extend ActiveSupport::Concern

    InvalidPackageTypeError = Class.new(StandardError)
    InvalidStatusError = Class.new(StandardError)

    private

    def packages_visible_to_user(user, within_group:)
      return ::Packages::Package.none unless within_group
      return ::Packages::Package.none unless Ability.allowed?(user, :read_group, within_group)

      projects = projects_visible_to_reporters(user, within_group: within_group)
      ::Packages::Package.for_projects(projects.select(:id))
    end

    def projects_visible_to_user(user, within_group:)
      return ::Project.none unless within_group
      return ::Project.none unless Ability.allowed?(user, :read_group, within_group)

      projects_visible_to_reporters(user, within_group: within_group)
    end

    def projects_visible_to_reporters(user, within_group:)
      if user.is_a?(DeployToken) && Feature.enabled?(:packages_finder_helper_deploy_token)
        user.accessible_projects
      else
        within_group.all_projects
                    .public_or_visible_to_user(user, ::Gitlab::Access::REPORTER)
      end
    end

    def package_type
      params[:package_type].presence
    end

    def filter_by_package_type(packages)
      return packages unless package_type
      raise InvalidPackageTypeError unless ::Packages::Package.package_types.key?(package_type)

      packages.with_package_type(package_type)
    end

    def filter_by_package_name(packages)
      return packages unless params[:package_name].present?

      packages.search_by_name(params[:package_name])
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
  end
end
