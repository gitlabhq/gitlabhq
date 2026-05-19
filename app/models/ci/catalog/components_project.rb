# frozen_string_literal: true

module Ci
  module Catalog
    # This class represents a project that contains one or more CI/CD components.
    # It is responsible for resolving component paths and retrieving catalog component data.
    class ComponentsProject
      TEMPLATES_DIR = 'templates'
      TEMPLATE_PATH_REGEX = '^templates\/[\w-]+(?:\/template)?\.yml$'
      COMPONENTS_LIMIT = 100

      ComponentData = Struct.new(:content, :path, keyword_init: true)

      def initialize(project, sha = project&.commit&.sha)
        @project = project
        @sha = sha
      end

      def fetch_component_paths(ref, limit: COMPONENTS_LIMIT)
        project.repository.search_files_by_regexp(TEMPLATE_PATH_REGEX, ref, limit: limit)
      end

      def extract_component_name(path)
        return unless path.match?(TEMPLATE_PATH_REGEX)

        dirname = File.dirname(path)
        filename = File.basename(path, '.*')

        if dirname == TEMPLATES_DIR
          filename
        else
          File.basename(dirname)
        end
      end

      def extract_spec(blob, path)
        result = Gitlab::Ci::Config::Yaml::Loader.new(blob, filename: path).load_uninterpolated_yaml

        raise result.error_class, result.error unless result.valid?

        result.spec
      end

      def find_catalog_components(component_names)
        return [] if component_names.empty?

        # Multiple versions of a component can have the same sha, so we return the latest one.
        version = project.catalog_resource_versions.by_sha(sha).latest
        return [] unless version

        version.components.template.where(name: component_names)
      end

      private

      attr_reader :project, :sha
    end
  end
end
