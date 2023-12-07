# frozen_string_literal: true

module Ci
  module Catalog
    class ComponentsProject
      # ComponentsProject is a type of Catalog Resource which contains one or more
      # CI/CD components.
      # It is responsible for retrieving the data of a component file, including the content, name, and file path.

      TEMPLATE_FILE = 'template.yml'
      TEMPLATES_DIR = 'templates'
      TEMPLATE_PATH_REGEX = '^templates\/[\w-]+(?:\/template)?\.yml$'
      COMPONENTS_LIMIT = 10

      ComponentData = Struct.new(:content, :path, keyword_init: true)

      def initialize(project, sha = project&.default_branch)
        @project = project
        @sha = sha
      end

      def fetch_component_paths(sha, limit: COMPONENTS_LIMIT)
        project.repository.search_files_by_regexp(TEMPLATE_PATH_REGEX, sha, limit: limit)
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

      def extract_inputs(blob)
        result = Gitlab::Ci::Config::Yaml::Loader.new(blob).load_uninterpolated_yaml

        raise result.error_class, result.error unless result.valid?

        result.inputs
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
