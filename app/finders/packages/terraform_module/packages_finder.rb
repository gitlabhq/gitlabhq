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

        if Feature.enabled?(:terraform_extract_terraform_package_model, Feature.current_request)
          ::Packages::TerraformModule::Package.none
        else
          ::Packages::Package.none
        end
      end

      private

      attr_reader :project, :params

      def packages
        result = if Feature.enabled?(:terraform_extract_terraform_package_model, Feature.current_request)
                   ::Packages::TerraformModule::Package
                     .for_projects(project)
                     .with_name(params[:package_name])
                     .installable
                 else
                   project
                     .packages
                     .with_name(params[:package_name])
                     .terraform_module
                     .installable
                 end

        params[:package_version] ? result.with_version(params[:package_version]) : result.has_version.order_version_desc
      end
    end
  end
end
