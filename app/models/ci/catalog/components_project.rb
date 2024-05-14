# frozen_string_literal: true

module Ci
  module Catalog
    # This class represents a project that contains one or more CI/CD components.
    # It is responsible for retrieving the data of a component file.
    class ComponentsProject
      TEMPLATE_FILE = 'template.yml'
      TEMPLATES_DIR = 'templates'
      TEMPLATE_PATH_REGEX = '^templates\/[\w-]+(?:\/template)?\.yml$'
      COMPONENTS_LIMIT = 30

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

      def extract_spec(blob)
        result = Gitlab::Ci::Config::Yaml::Loader.new(blob).load_uninterpolated_yaml

        raise result.error_class, result.error unless result.valid?

        result.spec
      end

      def fetch_component(component_name)
        return ComponentData.new unless component_name.index('/').nil?

        path = simple_template_path(component_name)
        content = fetch_content(path)

        if content.nil?
          path = complex_template_path(component_name)
          content = fetch_content(path)
        end

        ComponentData.new(content: content, path: path)
      end

      # TODO: This may retrieve the wrong component object if a simple and a complex component
      # have the same name for the given catalog resource version. We should complete
      # https://gitlab.com/gitlab-org/gitlab/-/issues/450737 to ensure unique component names.
      def find_catalog_component(component_name)
        # Multiple versions of a project can have the same sha, so we return the latest one.
        version = project.catalog_resource_versions.by_sha(sha).latest
        return unless version

        version.components.template.find_by_name(component_name)
      end

      private

      attr_reader :project, :sha

      def fetch_content(component_path)
        project.repository.blob_data_at(sha, component_path)
      end

      # A simple template consists of a single file
      def simple_template_path(component_name)
        File.join(TEMPLATES_DIR, "#{component_name}.yml")
      end

      # A complex template is directory-based and may consist of multiple files.
      # Given a path like "my-org/sub-group/the-project/templates/component"
      # returns the entry point path: "templates/component/template.yml".
      def complex_template_path(component_name)
        File.join(TEMPLATES_DIR, component_name, TEMPLATE_FILE)
      end
    end
  end
end
