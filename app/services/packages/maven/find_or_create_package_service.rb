# frozen_string_literal: true

module Packages
  module Maven
    class FindOrCreatePackageService < BaseService
      SNAPSHOT_TERM = '-SNAPSHOT'
      MAX_FILE_NAME_LENGTH = 5000
      DuplicatePackageError = Class.new(StandardError)

      def execute
        return ServiceResponse.error(message: 'File name is too long') if file_name_too_long?

        begin
          find_or_create_package
        rescue DuplicatePackageError
          retry # in case of a race condition, retry the block. 2nd attempt should succeed
        end
      end

      private

      def find_or_create_package
        package =
          ::Packages::Maven::PackageFinder.new(current_user, project, path: path)
          .execute&.last

        return ServiceResponse.error(message: 'Duplicate package is not allowed') if duplicate_error?(package)

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
          if file_name == Packages::Maven::Metadata.filename && !snapshot_version?
            package_name = path
            version = nil
          else
            package_name, _, version = path.rpartition('/')
          end

          package_params = {
            name: package_name,
            path: path,
            status: params[:status],
            version: version
          }

          service_response =
            ::Packages::Maven::CreatePackageService.new(project, current_user, package_params)
                                                   .execute

          if service_response.error?
            raise DuplicatePackageError if service_response.cause.name_taken?

            return service_response
          end

          package = service_response[:package]
        end

        package.create_build_infos!(params[:build])

        ServiceResponse.success(payload: { package: package })
      end

      def duplicate_error?(package)
        !Namespace::PackageSetting.duplicates_allowed?(package) && target_package_is_duplicate?(package)
      end

      def file_name_too_long?
        return false unless file_name

        file_name.size > MAX_FILE_NAME_LENGTH
      end

      def target_package_is_duplicate?(package)
        # duplicate metadata files can be uploaded multiple times
        return false if package.version.nil?

        existing_file_names = strip_snapshot_parts(
          package.package_files
                 .map(&:file_name)
                 .compact
        )

        published_file_name = strip_snapshot_parts_from(file_name)
        existing_file_names.include?(published_file_name)
      end

      def strip_snapshot_parts(file_names)
        return file_names unless snapshot_version?

        Array.wrap(file_names).map { |f| strip_snapshot_parts_from(f) }
      end

      def strip_snapshot_parts_from(file_name)
        return file_name unless snapshot_version?
        return unless file_name

        match_data = file_name.match(Gitlab::Regex::Packages::MAVEN_SNAPSHOT_DYNAMIC_PARTS)

        if match_data
          file_name.gsub(match_data.captures.last, '')
        else
          file_name
        end
      end

      def snapshot_version?
        path&.ends_with?(SNAPSHOT_TERM)
      end

      def path
        params[:path]
      end

      def file_name
        params[:file_name]
      end

      def lease_key
        "#{self.class.name.underscore}:#{project.id}_#{path}"
      end
    end
  end
end
