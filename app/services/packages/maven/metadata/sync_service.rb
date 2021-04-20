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

          result = success('Non existing versionless package(s). Nothing to do.')

          # update versionless package for plugins if it exists
          if metadata_package_file_for_plugins
            result = update_plugins_xml

            return result if result.error?
          end

          # update versionless_package for versions if it exists
          return update_versions_xml if metadata_package_file_for_versions

          result
        end

        private

        def update_versions_xml
          update_xml(
            kind: :versions,
            package_file: metadata_package_file_for_versions,
            service_class: CreateVersionsXmlService,
            payload_empty_field: :empty_versions
          )
        end

        def update_plugins_xml
          update_xml(
            kind: :plugins,
            package_file: metadata_package_file_for_plugins,
            service_class: CreatePluginsXmlService,
            payload_empty_field: :empty_plugins
          )
        end

        def update_xml(kind:, package_file:, service_class:, payload_empty_field:)
          return error("Metadata file for #{kind} is too big") if package_file.size > MAX_FILE_SIZE

          package_file.file.use_open_file do |file|
            result = service_class.new(metadata_content: file, package: package_file.package)
                                  .execute

            next result unless result.success?
            next success("No changes for #{kind} xml") unless result.payload[:changes_exist]

            if result.payload[payload_empty_field]
              package_file.package.destroy!
              success("Versionless package for #{kind} destroyed")
            else
              AppendPackageFileService.new(metadata_content: result.payload[:metadata_content], package: package_file.package)
                                      .execute
            end
          end
        end

        def metadata_package_file_for_versions
          strong_memoize(:metadata_file_for_versions) do
            metadata_package_file_for(versionless_package_for_versions)
          end
        end

        def versionless_package_for_versions
          strong_memoize(:versionless_package_for_versions) do
            versionless_package_named(package_name)
          end
        end

        def metadata_package_file_for_plugins
          strong_memoize(:metadata_package_file_for_plugins) do
            pkg_name = package_name_for_plugins
            next unless pkg_name

            metadata_package_file_for(versionless_package_named(package_name_for_plugins))
          end
        end

        def metadata_package_file_for(package)
          return unless package

          package.package_files
                 .with_file_name(Metadata.filename)
                 .recent
                 .first
        end

        def versionless_package_named(name)
          project.packages
                 .maven
                 .displayable
                 .with_name(name)
                 .with_version(nil)
                 .first
        end

        def package_name
          params[:package_name]
        end

        def package_name_for_plugins
          return unless versionless_package_for_versions

          group = versionless_package_for_versions.maven_metadatum.app_group
          group.tr('.', '/')
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
