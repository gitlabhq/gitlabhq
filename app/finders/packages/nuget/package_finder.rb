# frozen_string_literal: true
module Packages
  module Nuget
    class PackageFinder
      MAX_PACKAGES_COUNT = 50

      def initialize(project, package_name:, package_version: nil, limit: MAX_PACKAGES_COUNT)
        @project = project
        @package_name = package_name
        @package_version = package_version
        @limit = limit
      end

      def execute
        packages.limit_recent(@limit)
      end

      private

      def packages
        result = @project.packages
                         .nuget
                         .has_version
                         .processed
                         .with_name_like(@package_name)
        result = result.with_version(@package_version) if @package_version.present?
        result
      end
    end
  end
end
