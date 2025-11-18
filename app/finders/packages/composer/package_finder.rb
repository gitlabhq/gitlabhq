# frozen_string_literal: true

module Packages
  module Composer
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def execute
        packages
      end

      private

      def packages
        results = filter_by_exact_package_name(base)
        results = results.with_composer_target(params[:target_sha]) if params[:target_sha]
        results
      end

      override :group_packages
      def group_packages
        packages_visible_to_user(
          @current_user,
          within_group: @project_or_group,
          with_package_registry_enabled: true
        )
      end

      override :packages_class
      def packages_class
        ::Packages::Composer::Package
      end
    end
  end
end
