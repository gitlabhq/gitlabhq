module Packages
  class CreateMavenPackageService < BaseService
    def execute
      package = Packages::Package.create(project: project)

      Packages::MavenMetadatum.create!(
        package: package,
        app_group: params[:app_group],
        app_name: params[:app_name],
        app_version: params[:app_version]
      )
    end
  end
end
