# frozen_string_literal: true

module Packages
  module Npm
    class PackagesForUserFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def execute
        packages
      end

      private

      def packages
        base.with_name(@params[:package_name])
      end

      override :group_packages
      def group_packages
        packages_visible_to_user(@current_user, within_group: @project_or_group, with_package_registry_enabled: true)
      end

      # This overrides projects_visible_to_reporters in app/finders/concerns/packages/finder_helper.rb
      # to implement npm-specific optimizations
      def projects_visible_to_reporters(user, within_group:, _within_public_package_registry: false)
        return user.accessible_projects if user.is_a?(DeployToken)

        access = if Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, within_group.root_ancestor)
                   ::Gitlab::Access::GUEST
                 else
                   ::Gitlab::Access::REPORTER
                 end

        ::Project.public_or_visible_to_user(user, access).by_any_overlap_with_traversal_ids(within_group.id)
      end

      override :packages_class
      def packages_class
        ::Packages::Npm::Package
      end
    end
  end
end
