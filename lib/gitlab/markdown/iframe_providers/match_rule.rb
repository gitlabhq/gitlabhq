# frozen_string_literal: true

module Gitlab
  module Markdown
    module IframeProviders
      class MatchRule
        PLACEHOLDER_SEGMENT = /\A#{PLACEHOLDER}\z/o

        attr_reader :host, :path_segments, :params

        def self.from_config(provider_id, config)
          error = ->(message) { raise ConfigError, "provider '#{provider_id}': match rule #{message}" }

          error.call('must be a mapping') unless config.is_a?(Hash)

          host = config['host']
          error.call("missing 'host'") unless host.is_a?(String) && host.present?

          path = config['path']
          error.call("missing 'path'") unless path.is_a?(String) && path.present?
          error.call("'path' must start with / (got #{path.inspect})") unless path.start_with?('/')

          params = config.fetch('params', [])
          error.call("'params' must be a list of strings") unless params.is_a?(Array) && params.all?(String)

          new(host: host.downcase, path_segments: path[1..].split('/'), params: params)
        end

        def initialize(host:, path_segments:, params:)
          @host = host
          @path_segments = path_segments
          @params = params
        end

        def capture_names
          path_segments.filter_map { |segment| placeholder_name(segment) } + params
        end

        def match(uri)
          return unless uri.normalized_host == host

          captures = match_path(uri.path)
          return unless captures

          match_params(uri, captures)
        end

        private

        def placeholder_name(segment)
          segment[PLACEHOLDER_SEGMENT, 1]
        end

        def match_path(path)
          return unless path.start_with?('/')

          actual_segments = path[1..].split('/')
          return unless actual_segments.length >= path_segments.length

          captures = {}

          matched = path_segments.zip(actual_segments).all? do |rule_segment, actual_segment|
            name = placeholder_name(rule_segment)

            if name.nil?
              rule_segment == actual_segment
            elsif actual_segment.empty?
              false
            else
              captures[name] = Addressable::URI.unencode_component(actual_segment)
            end
          end

          captures if matched
        end

        def match_params(uri, captures)
          return captures if params.empty?

          query_values = uri.query_values
          return unless query_values

          matched = params.all? do |name|
            value = query_values[name]
            captures[name] = value if value.present?
          end

          captures if matched
        end
      end
    end
  end
end
