# frozen_string_literal: true

require 'pathname'
require 'yaml'

module Keeps
  module Helpers
    # Allowlist of indexes the Keep must never propose for removal. Backed
    # by keeps/cleanup_unused_indexes/index_keep_list.yml; the file header
    # documents the entry format.
    class IndexKeepList
      Error = Class.new(StandardError)

      REQUIRED_KEYS = %w[reason added_by added_on].freeze
      DEFAULT_YAML_PATH = 'keeps/cleanup_unused_indexes/index_keep_list.yml'

      def initialize(yaml_path: nil)
        @yaml_path = Pathname.new(yaml_path || Rails.root.join(DEFAULT_YAML_PATH))
      end

      def exempt?(schema, name)
        entries.key?("#{schema}.#{name}")
      end

      def entries
        @entries ||= load_entries
      end

      private

      def load_entries
        data = YAML.safe_load(File.read(@yaml_path)) || {}

        data.each do |id, fields|
          missing = REQUIRED_KEYS - (fields || {}).keys
          raise Error, "#{@yaml_path}: `#{id}` missing required keys: #{missing.join(', ')}" if missing.any?
        end

        data
      end
    end
  end
end
