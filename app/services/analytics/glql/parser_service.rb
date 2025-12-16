# frozen_string_literal: true

require 'yaml'

module Analytics
  module Glql
    # Service for parsing incoming YAML configurations from API::Glql
    # It is then returned for GLQL processing
    class ParserService
      # Frontmatter format: ---\nconfig\n---\nquery
      # This regex handles both empty and non-empty config sections
      FRONTMATTER_REGEX = /\A---\n(?<config>.*?)\n---\n(?<query>.*)\z/m
      MAX_INPUT_SIZE = 10_000 # 10KB limit

      def initialize(glql_yaml:)
        raise ArgumentError, "Input exceeds maximum size" if glql_yaml.bytesize > MAX_INPUT_SIZE

        @glql_yaml = glql_yaml
      end

      def execute
        config, query = get_frontmatter_yaml
        config, query = get_standard_yaml if config.empty? || query.empty?

        { config: config, query: query }
      end

      private

      attr_reader :glql_yaml

      def get_frontmatter_yaml
        frontmatter_match = glql_yaml.match(FRONTMATTER_REGEX)
        query = ''
        config = {}

        begin
          if frontmatter_match
            # Frontmatter format
            config_yaml = frontmatter_match[:config].strip
            query = frontmatter_match[:query].strip
            config = config_yaml.empty? ? {} : YAML.safe_load(config_yaml)
          end

          [config, query]
        rescue Psych::Exception
          [{}, '']
        end
      end

      def get_standard_yaml
        # Check if it's pure YAML (no frontmatter)
        begin
          parsed = YAML.safe_load(glql_yaml)

          if parsed.is_a?(Hash) && parsed['query']
            # Pure YAML format with query key
            query = parsed.delete('query')
            config = parsed
          else
            # Assume it's just a query string
            query = glql_yaml.strip
            config = {}
          end
        rescue Psych::SyntaxError, Psych::Exception
          # Not valid YAML, treat as plain query
          query = glql_yaml.strip
          config = {}
        end

        [config, query]
      end
    end
  end
end
