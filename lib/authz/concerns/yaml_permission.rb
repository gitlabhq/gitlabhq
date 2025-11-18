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

        def available_for_tokens
          all.values.select(&:available_for_tokens?)
        end
        strong_memoize_attr :available_for_tokens

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

      def available_for_tokens?
        definition[:available_for_tokens] || false
      end
    end
  end
end
