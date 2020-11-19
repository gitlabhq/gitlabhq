# frozen_string_literal: true
module Packages
  module Npm
    class PackageFinder
      attr_reader :project, :package_name

      delegate :find_by_version, to: :execute

      def initialize(project, package_name)
        @project = project
        @package_name = package_name
      end

      def execute
        return Packages::Package.none unless project

        packages
      end

      private

      def packages
        project.packages
          .npm
          .with_name(package_name)
          .last_of_each_version
          .preload_files
      end
    end
  end
end
