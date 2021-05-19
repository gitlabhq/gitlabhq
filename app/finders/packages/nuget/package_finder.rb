# frozen_string_literal: true

module Packages
  module Nuget
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      MAX_PACKAGES_COUNT = 300

      def execute
        packages.limit_recent(@params[:limit] || MAX_PACKAGES_COUNT)
      end

      private

      def packages
        result = base.nuget
                     .has_version
                     .with_name_like(@params[:package_name])
        result = result.with_version(@params[:package_version]) if @params[:package_version].present?
        result
      end
    end
  end
end
