# frozen_string_literal: true
module Packages
  class CreateMavenPackageService < BaseService
    def execute
      app_group, _, app_name = params[:name].rpartition('/')
      app_group.tr!('/', '.')

      project.packages.create!(
        name: params[:name],
        version: params[:version],
        maven_metadatum_attributes: {
          path: params[:path],
          app_group: app_group,
          app_name: app_name,
          app_version: params[:version]
        }
      )
    end
  end
end
