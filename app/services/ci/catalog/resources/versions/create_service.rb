# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Versions
        class CreateService
          def initialize(release)
            @project = release.project
            @release = release
            @errors = []
            @version = nil
            @components_project = Ci::Catalog::ComponentsProject.new(project)
          end

          def execute
            build_catalog_resource_version
            fetch_and_build_components
            publish_catalog_resource!

            if errors.empty?
              ServiceResponse.success
            else
              ServiceResponse.error(message: errors.flatten.first(10).join(', '))
            end
          end

          private

          attr_reader :project, :errors, :release, :components_project

          def build_catalog_resource_version
            return error('Project is not a catalog resource') unless project.catalog_resource

            @version = Ci::Catalog::Resources::Version.new(
              release: release,
              catalog_resource: project.catalog_resource,
              project: project,
              semver: release.tag
            )
          end

          def fetch_and_build_components
            return if errors.present?

            max_components = Ci::Catalog::ComponentsProject::COMPONENTS_LIMIT
            component_paths = components_project.fetch_component_paths(release.sha, limit: max_components + 1)

            if component_paths.size > max_components
              return error("Release cannot contain more than #{max_components} components")
            end

            build_components(component_paths)
          end

          def build_components(component_paths)
            paths_with_oids = component_paths.map { |path| [release.sha, path] }
            blobs = project.repository.blobs_at(paths_with_oids)

            blobs.each do |blob|
              metadata = extract_metadata(blob)
              build_catalog_resource_component(metadata)
            end
          rescue ::Gitlab::Config::Loader::FormatError => e
            error(e)
          end

          def extract_metadata(blob)
            component_name = components_project.extract_component_name(blob.path)

            {
              name: component_name,
              spec: components_project.extract_spec(blob.data)
            }
          end

          def build_catalog_resource_component(metadata)
            return if errors.present?

            component = @version.components.build(
              name: metadata[:name],
              project: @version.project,
              spec: metadata[:spec],
              catalog_resource: @version.catalog_resource,
              created_at: Time.current
            )

            return if component.valid?

            error("Build component error: #{component.errors.full_messages.join(', ')}")
          end

          def publish_catalog_resource!
            return if errors.present?

            ::Ci::Catalog::Resources::Version.transaction do
              BulkInsertableAssociations.with_bulk_insert do
                @version.save!
              end

              project.catalog_resource.publish!
            end
          end

          def error(message)
            errors << message
          end
        end
      end
    end
  end
end
