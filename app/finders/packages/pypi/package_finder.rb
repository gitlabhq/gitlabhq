# frozen_string_literal: true

module Packages
  module Pypi
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      extend ::Gitlab::Utils::Override

      def initialize(current_user, project_or_group, params = {})
        if Feature.enabled?(:pypi_extract_pypi_package_model, Feature.current_request)
          params[:packages_class] = ::Packages::Pypi::Package
        end

        super
      end

      def execute
        packages.by_file_name_and_sha256(@params[:filename], @params[:sha256])
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
        # PyPI finds packages without checking permissions.
        # The package download endpoint uses obfuscation to secure the file
        # instead of authentication. This is behavior the PyPI package
        # manager defines and is not something GitLab controls.
        packages_class.for_projects(
          @project_or_group.all_projects.select(:id)
        ).installable
      end
    end
  end
end
