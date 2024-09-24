# frozen_string_literal: true

module Packages
  module Pypi
    class PackagesFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def initialize(current_user, project_or_group, params = {})
        if Feature.enabled?(:pypi_extract_pypi_package_model, Feature.current_request)
          params[:packages_class] = ::Packages::Pypi::Package
        end

        super
      end

      def execute
        return packages unless @params[:package_name]

        packages.with_normalized_pypi_name(@params[:package_name])
      end

      private

      def packages
        if Feature.enabled?(:pypi_extract_pypi_package_model, Feature.current_request)
          base.has_version
        else
          base.pypi.has_version
        end
      end

      override :group_packages
      def group_packages
        packages_visible_to_user(
          @current_user,
          within_group: @project_or_group,
          with_package_registry_enabled: true
        )
      end
    end
  end
end
