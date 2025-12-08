# frozen_string_literal: true

module Authz
  module Concerns
    module YamlPermission
      extend ActiveSupport::Concern

      class_methods do
        include ::Gitlab::Utils::StrongMemoize

        def all
          @all ||= load_all
        end

        def get(name)
          all[name.to_sym]
        end

        def defined?(name)
          all.key?(name.to_sym)
        end

        private

        def load_all
          items = {}

          Dir.glob(config_path).each do |file|
            item = load_from_file(file)
            items[item.name.to_sym] = item
          end

          items
        end

        def load_from_file(path)
          definition_data = File.read(path)
          definition = YAML.safe_load(definition_data)
          definition.deep_symbolize_keys!
          new(definition, path)
        end

        def config_path
          raise NotImplementedError, "#{self} must implement .config_path"
        end
      end

      attr_reader :definition, :source_file

      def initialize(definition, source_file)
        @definition = definition
        @source_file = source_file
      end

      def name
        definition[:name]
      end

      def description
        definition[:description]
      end

      def action
        File.basename(source_file, '.yml')
      end

      def resource
        # return nil if file is not under a directory
        return unless File.fnmatch(self.class.config_path.to_s, source_file)

        File.basename(File.dirname(source_file))
      end

      def feature_category
        definition[:feature_category]
      end

      def boundaries
        definition[:boundaries] || []
      end
    end
  end
end
