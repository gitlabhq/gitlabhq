module Packages
  class CreateMavenPackageService < BaseService
    def execute
      package = Packages::Package.create!(
        project: project,
        name: full_app_name,
        version: params[:app_version]
      )

      Packages::MavenMetadatum.create!(
        package: package,
        app_group: params[:app_group],
        app_name: params[:app_name],
        app_version: params[:app_version]
      )
    end

    private

    def full_app_name
      params[:app_group] + '/' + params[:app_name]
    end
  end
end
