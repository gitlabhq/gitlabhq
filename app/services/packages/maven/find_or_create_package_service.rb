# frozen_string_literal: true
module Packages
  module Maven
    class FindOrCreatePackageService < BaseService
      MAVEN_METADATA_FILE = 'maven-metadata.xml'.freeze
      SNAPSHOT_TERM = '-SNAPSHOT'.freeze

      def execute
        package =
          ::Packages::Maven::PackageFinder.new(params[:path], current_user, project: project)
                                          .execute

        unless package
          # Maven uploads several files during `mvn deploy` in next order:
          #   - my-company/my-app/1.0-SNAPSHOT/my-app.jar
          #   - my-company/my-app/1.0-SNAPSHOT/my-app.pom
          #   - my-company/my-app/1.0-SNAPSHOT/maven-metadata.xml
          #   - my-company/my-app/maven-metadata.xml
          #
          # The last xml file does not have VERSION in URL because it contains
          # information about all versions. When uploading such file, we create
          # a package with a version set to `nil`. The xml file with a version
          # is only created and uploaded for snapshot versions.
          #
          # Gradle has a different upload order:
          #   - my-company/my-app/1.0-SNAPSHOT/maven-metadata.xml
          #   - my-company/my-app/1.0-SNAPSHOT/my-app.jar
          #   - my-company/my-app/1.0-SNAPSHOT/my-app.pom
          #   - my-company/my-app/maven-metadata.xml
          #
          # The first upload has to create the proper package (the one with the version set).
          if params[:file_name] == MAVEN_METADATA_FILE && !params[:path]&.ends_with?(SNAPSHOT_TERM)
            package_name, version = params[:path], nil
          else
            package_name, _, version = params[:path].rpartition('/')
          end

          package_params = {
            name: package_name,
            path: params[:path],
            version: version
          }

          package =
            ::Packages::Maven::CreatePackageService.new(project, current_user, package_params)
                                                   .execute
        end

        package.build_infos.create!(pipeline: params[:build].pipeline) if params[:build].present?

        package
      end
    end
  end
end
