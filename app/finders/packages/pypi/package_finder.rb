# frozen_string_literal: true

module Packages
  module Pypi
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      def execute
        packages.by_file_name_and_sha256(@params[:filename], @params[:sha256])
      end

      private

      def packages
        base.pypi.has_version
      end

      def group_packages
        # PyPI finds packages without checking permissions.
        # The package download endpoint uses obfuscation to secure the file
        # instead of authentication. This is behavior the PyPI package
        # manager defines and is not something GitLab controls.
        ::Packages::Package.for_projects(
          @project_or_group.all_projects.select(:id)
        ).installable
      end
    end
  end
end
