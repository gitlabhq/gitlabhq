# frozen_string_literal: true

module Packages
  module TerraformModule
    class PackagesFinder
      def initialize(project, params = {})
        @project = project
        @params = params
      end

      def execute
        return ::Packages::Package.none unless project && params[:package_name]

        packages
      end

      private

      attr_reader :project, :params

      def packages
        result = project
          .packages
          .with_name(params[:package_name])
          .terraform_module
          .installable

        params[:package_version] ? result.with_version(params[:package_version]) : result.has_version.order_version_desc
      end
    end
  end
end
