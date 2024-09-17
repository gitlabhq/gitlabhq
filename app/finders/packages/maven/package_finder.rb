# frozen_string_literal: true

module Packages
  module Maven
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def execute
        packages
      end

      private

      def packages
        matching_packages = base.only_maven_packages_with_path(@params[:path], use_cte: group?)
        matching_packages = matching_packages.order_by_package_file if @params[:order_by_package_file]

        matching_packages
      end

      override :group_packages
      def group_packages
        if Feature.enabled?(:maven_remove_permissions_check_from_finder, @project_or_group)
          packages_for(@current_user, within_group: @project_or_group)
        elsif ::Feature.enabled?(:allow_anyone_to_pull_public_maven_packages_on_group_level, @project_or_group)
          packages_visible_to_user_including_public_registries(@current_user, within_group: @project_or_group)
        else
          super
        end
      end
    end
  end
end
