# frozen_string_literal: true
module Packages
  module Maven
    class FindOrCreatePackageService < BaseService
      SNAPSHOT_TERM = '-SNAPSHOT'

      def execute
        package =
          ::Packages::Maven::PackageFinder.new(current_user, project, path: params[:path])
                                          .execute

        unless Namespace::PackageSetting.duplicates_allowed?(package)
          return ServiceResponse.error(message: 'Duplicate package is not allowed') if target_package_is_duplicate?(package)
        end

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
          if params[:file_name] == Packages::Maven::Metadata.filename && !params[:path]&.ends_with?(SNAPSHOT_TERM)
            package_name = params[:path]
            version = nil
          else
            package_name, _, version = params[:path].rpartition('/')
          end

          package_params = {
            name: package_name,
            path: params[:path],
            status: params[:status],
            version: version
          }

          package =
            ::Packages::Maven::CreatePackageService.new(project, current_user, package_params)
                                                   .execute
        end

        package.build_infos.safe_find_or_create_by!(pipeline: params[:build].pipeline) if params[:build].present?

        ServiceResponse.success(payload: { package: package })
      end

      private

      def extname(filename)
        return if filename.blank?

        File.extname(filename)
      end

      def target_package_is_duplicate?(package)
        # duplicate metadata files can be uploaded multiple times
        return false if package.version.nil?

        package
          .package_files
          .map { |file| extname(file.file_name) }
          .compact
          .include?(extname(params[:file_name]))
      end
    end
  end
end
