# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Versions
        # This service is called from the Versions::CreateService and
        # responsible for building components for a release version.
        class BuildComponentsService
          MAX_COMPONENTS = Ci::Catalog::ComponentsProject::COMPONENTS_LIMIT

          def initialize(release, version, components_data)
            @release = release
            @version = version
            @components_data = components_data
            @project = release.project
            @components_project = Ci::Catalog::ComponentsProject.new(project)
            @errors = []
          end

          def execute
            components = if components_data
                           build_components_from_passed_data
                         else
                           build_components_from_fetched_data
                         end

            if errors.empty?
              ServiceResponse.success(payload: components)
            else
              ServiceResponse.error(message: errors.flatten.first(10).join(', '))
            end
          end

          private

          attr_reader :release, :version, :project, :components_project, :components_data, :errors

          def build_components_from_passed_data
            check_number_of_components(components_data.size)
            return if errors.present?

            components_data.map do |component_data|
              build_catalog_resource_component(component_data)
            end
          end

          def build_components_from_fetched_data
            component_paths = components_project.fetch_component_paths(release.sha, limit: MAX_COMPONENTS + 1)

            check_number_of_components(component_paths.size)
            return if errors.present?

            build_components_from_paths(component_paths)
          end

          def build_components_from_paths(component_paths)
            paths_with_oids = component_paths.map { |path| [release.sha, path] }
            blobs = project.repository.blobs_at(paths_with_oids)

            blobs.map do |blob|
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
              spec: components_project.extract_spec(blob.data),
              component_type: 'template'
            }
          end

          def check_number_of_components(size)
            return if size <= MAX_COMPONENTS

            error("Release cannot contain more than #{MAX_COMPONENTS} components")
          end

          def build_catalog_resource_component(metadata)
            return if errors.present?

            component = Ci::Catalog::Resources::Component.new(
              name: metadata[:name],
              project: version.project,
              spec: metadata[:spec],
              component_type: metadata[:component_type],
              version: version,
              catalog_resource: version.catalog_resource,
              created_at: Time.current
            )

            return component if component.valid?

            error("Build component error: #{component.errors.full_messages.join(', ')}")
          rescue ArgumentError => e
            # In Rails 7.1, we'll have a better way to handle this error; https://github.com/rails/rails/pull/49100
            # Ci::Catalog::Resources::Component: `enum resource_type: { template: 1 }, validate: true`
            error(e.message)
          end

          def error(message)
            errors << message
          end
        end
      end
    end
  end
end
