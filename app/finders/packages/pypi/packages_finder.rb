# frozen_string_literal: true

module Packages
  module Pypi
    class PackagesFinder < ::Packages::GroupOrProjectPackageFinder
      def execute
        return packages unless @params[:package_name]

        packages.with_normalized_pypi_name(@params[:package_name])
      end

      private

      def packages
        base.pypi.has_version
      end
    end
  end
end
