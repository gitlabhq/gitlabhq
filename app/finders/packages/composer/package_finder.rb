# frozen_string_literal: true

module Packages
  module Composer
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override
      include Gitlab::Utils::StrongMemoize

      def execute
        return packages if packages_composer_read_from_detached_table?

        packages.preload_composer
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
        if packages_composer_read_from_detached_table?
          ::Packages::Composer::Package
        else
          ::Packages::Composer::Sti::Package
        end
      end

      def packages_composer_read_from_detached_table?
        Feature.enabled?(:packages_composer_read_from_detached_table, Feature.current_request)
      end
      strong_memoize_attr :packages_composer_read_from_detached_table?
    end
  end
end
