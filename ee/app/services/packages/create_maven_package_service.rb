# frozen_string_literal: true
module Packages
  class CreateMavenPackageService < BaseService
    def execute
      package = project.packages.create!(
        name: params[:name],
        version: params[:version]
      )

      app_group, _, app_name = params[:name].rpartition('/')
      app_group.tr!('/', '.')

      package.create_maven_metadatum!(
        path: params[:path],
        app_group: app_group,
        app_name: app_name,
        app_version: params[:version]
      )

      package
    end
  end
end
