# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      module Bundle
        # Compiles every component of a published catalog version as its
        # publisher, so a bundle can never carry content its publisher could not
        # read. Returns the compiled content per component; does not persist.
        class CompileService
          def initialize(version)
            @version = version
          end

          def execute
            return error('Version has no publisher', :missing_publisher) unless version.published_by

            components = component_contents.map do |name, content|
              { name: name, content: compile(content) }
            end

            ServiceResponse.success(payload: { components: components })
          rescue ::Gitlab::Ci::Catalog::Bundle::Compiler::CompileError => e
            error(e.message, :compile_failed)
          end

          private

          attr_reader :version

          def component_contents
            components_project = ::Ci::Catalog::ComponentsProject.new(version.project)
            paths = components_project.fetch_component_paths(version.sha)

            version.project.repository.blobs_at(paths.map { |path| [version.sha, path] }).compact.map do |blob|
              [components_project.extract_component_name(blob.path), blob.data]
            end
          end

          def compile(content)
            ::Gitlab::Ci::Catalog::Bundle::Compiler.new(
              content: content,
              project: version.project,
              sha: version.sha,
              current_user: version.published_by
            ).compile
          end

          def error(message, reason)
            ServiceResponse.error(message: message, reason: reason)
          end
        end
      end
    end
  end
end
