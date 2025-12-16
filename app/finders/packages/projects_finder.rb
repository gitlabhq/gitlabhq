# frozen_string_literal: true

module Packages
  class ProjectsFinder
    def initialize(current_user:, group:, params: {})
      @current_user = current_user
      @group = group
      @params = params
    end

    def execute
      return Project.none unless group || current_user.is_a?(DeployToken)

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

    private

    attr_reader :current_user, :group, :params

    def visible_projects
      public_or_visible = ::Project.public_or_visible_to_user(current_user, access)

      return public_or_visible.or(with_public_package_registry) if params[:within_public_package_registry]

      public_or_visible
    end

    def access
      return ::Gitlab::Access::GUEST if Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, group.root_ancestor)

      ::Gitlab::Access::REPORTER
    end

    def with_public_package_registry
      ::ProjectFeature.with_feature_access_level(:package_registry, ::ProjectFeature::PUBLIC)
    end

    def groups
      return [group] if params[:exclude_subgroups]

      group.self_and_descendants
    end
  end
end
