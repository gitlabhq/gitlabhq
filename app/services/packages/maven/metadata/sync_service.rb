# frozen_string_literal: true

module Packages
  module Maven
    module Metadata
      class SyncService < BaseContainerService
        include Gitlab::Utils::StrongMemoize

        alias_method :project, :container

        MAX_FILE_SIZE = 10.megabytes.freeze

        def execute
          return error('Blank package name') unless package_name
          return error('Not allowed') unless Ability.allowed?(current_user, :destroy_package, project)
          return error('Non existing versionless package') unless versionless_package_for_versions
          return error('Non existing metadata file for versions') unless metadata_package_file_for_versions

          update_versions_xml
        end

        private

        def update_versions_xml
          return error('Metadata file for versions is too big') if metadata_package_file_for_versions.size > MAX_FILE_SIZE

          metadata_package_file_for_versions.file.use_open_file do |file|
            result = CreateVersionsXmlService.new(metadata_content: file, package: versionless_package_for_versions)
                                             .execute

            next result unless result.success?
            next success('No changes for versions xml') unless result.payload[:changes_exist]

            if result.payload[:empty_versions]
              versionless_package_for_versions.destroy!
              success('Versionless package for versions destroyed')
            else
              AppendPackageFileService.new(metadata_content: result.payload[:metadata_content], package: versionless_package_for_versions)
                                      .execute
            end
          end
        end

        def metadata_package_file_for_versions
          strong_memoize(:metadata_file_for_versions) do
            versionless_package_for_versions.package_files
                                            .with_file_name(Metadata.filename)
                                            .recent
                                            .first
          end
        end

        def versionless_package_for_versions
          strong_memoize(:versionless_package_for_versions) do
            project.packages
                   .maven
                   .displayable
                   .with_name(package_name)
                   .with_version(nil)
                   .first
          end
        end

        def package_name
          params[:package_name]
        end

        def error(message)
          ServiceResponse.error(message: message)
        end

        def success(message)
          ServiceResponse.success(message: message)
        end
      end
    end
  end
end
