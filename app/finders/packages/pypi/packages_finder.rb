# frozen_string_literal: true

module Packages
  module Pypi
    class PackagesFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def execute
        return packages unless @params[:package_name]

        packages.with_normalized_pypi_name(@params[:package_name])
      end

      private

      def packages
        base.has_version
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
        ::Packages::Pypi::Package
      end
    end
  end
end
