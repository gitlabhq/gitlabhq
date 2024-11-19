# frozen_string_literal: true

module Packages
  module TerraformModule
    class PackagesFinder
      def initialize(project, params = {})
        @project = project
        @params = params
      end

      def execute
        return packages if project && params[:package_name]

        ::Packages::TerraformModule::Package.none
      end

      private

      attr_reader :project, :params

      def packages
        result = ::Packages::TerraformModule::Package
                   .for_projects(project)
                   .with_name(params[:package_name])
                   .installable

        params[:package_version] ? result.with_version(params[:package_version]) : result.has_version.order_version_desc
      end
    end
  end
end
