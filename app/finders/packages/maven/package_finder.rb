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
        else
          packages_visible_to_user_including_public_registries(@current_user, within_group: @project_or_group)
        end
      end

      override :packages_class
      def packages_class
        if Feature.enabled?(:maven_extract_package_model, Feature.current_request)
          ::Packages::Maven::Package
        else
          super
        end
      end
    end
  end
end
