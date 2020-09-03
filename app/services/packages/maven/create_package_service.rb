# frozen_string_literal: true
module Packages
  module Maven
    class CreatePackageService < ::Packages::CreatePackageService
      def execute
        app_group, _, app_name = params[:name].rpartition('/')
        app_group.tr!('/', '.')

        package = create_package!(:maven,
          maven_metadatum_attributes: {
            path: params[:path],
            app_group: app_group,
            app_name: app_name,
            app_version: params[:version]
          }
        )

        build = params[:build]
        package.create_build_info!(pipeline: build.pipeline) if build.present?

        package
      end
    end
  end
end
