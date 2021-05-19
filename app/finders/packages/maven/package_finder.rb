# frozen_string_literal: true

module Packages
  module Maven
    class PackageFinder < ::Packages::GroupOrProjectPackageFinder
      def execute
        packages.last
      end

      def execute!
        packages.last!
      end

      private

      def packages
        matching_packages = base.only_maven_packages_with_path(@params[:path], use_cte: group?)
        matching_packages = matching_packages.order_by_package_file if @params[:order_by_package_file]

        matching_packages
      end
    end
  end
end
