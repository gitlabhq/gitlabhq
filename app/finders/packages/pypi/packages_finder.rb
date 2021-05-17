# frozen_string_literal: true

module Packages
  module Pypi
    class PackagesFinder < ::Packages::GroupOrProjectPackageFinder
      def execute!
        results = packages.with_normalized_pypi_name(@params[:package_name])
        raise ActiveRecord::RecordNotFound if results.empty?

        results
      end

      private

      def packages
        base.pypi.has_version
      end
    end
  end
end
