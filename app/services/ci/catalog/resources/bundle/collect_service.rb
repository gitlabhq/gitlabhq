# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Bundle
        # Collects every component of a published catalog version into a bundle.
        # Returns the bundle per component, or every rejection; does not persist.
        class CollectService
          def initialize(version)
            @version = version
            @errors = []
          end

          def execute
            components = component_paths.filter_map { |name, path| collect(name, path) }

            return ServiceResponse.success(payload: { components: components }) if errors.empty?

            ServiceResponse.error(message: errors.join('; '), payload: { errors: errors }, reason: :collect_failed)
          end

          private

          attr_reader :version, :errors

          def collect(name, path)
            files = ::Gitlab::Ci::Catalog::Bundle::Collector.new(
              project: version.project,
              sha: version.sha,
              entry_path: path
            ).collect

            { name: name, content: bundle(name, path, files) }
          rescue ::Gitlab::Ci::Catalog::Bundle::Collector::CollectError => e
            errors.concat(e.errors.map { |error| "Component `#{name}`: #{error}" })

            nil
          end

          def bundle(name, path, files)
            ::Gitlab::Ci::Catalog::Bundle::Format.dump(
              name: name,
              version: version.semver.to_s,
              sha: version.sha,
              entry_path: path,
              files: files
            )
          end

          def component_paths
            components_project = ::Ci::Catalog::ComponentsProject.new(version.project)

            components_project.fetch_component_paths(version.sha).map do |path|
              [components_project.extract_component_name(path), path]
            end
          end
        end
      end
    end
  end
end
