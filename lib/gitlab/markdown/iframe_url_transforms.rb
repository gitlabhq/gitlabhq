# frozen_string_literal: true

require 'addressable'

module Gitlab
  module Markdown
    module IframeUrlTransforms
      TRANSFORMS_PATH = Rails.root.join('config/iframe_url_transforms.yml').freeze

      Rule = Struct.new(:host, :path_segments, :params, :matches, :template, keyword_init: true)

      class << self
        # Transform URLs according to rules in TRANSFORMS_PATH.
        #
        # Rules are evaluated in order; first match wins.
        # If no rule matches, the input is returned unchanged.
        #
        # Matching is done via URI parsing:
        #   - "host" is matched exactly against the URL's hostname
        #   - "path" is a prefix pattern with optional {named} captures for path segments
        #   - "params" lists query parameter names whose values are extracted
        #   - "match" provides per-capture allowed-value constraints
        #
        # The "to" template uses {name} placeholders, expanded from both path captures and
        # extracted query parameters.
        def transform(url)
          return url if url.blank?

          uri = begin
            Addressable::URI.parse(url)
          rescue Addressable::URI::InvalidURIError
            nil
          end

          return url unless uri
          return url unless uri.scheme == 'https'

          matching_rule = nil
          captures = nil

          rules.each do |rule|
            captures = match_rule(uri, rule)
            next unless captures

            matching_rule = rule
            break
          end

          return url unless matching_rule

          expand_template(matching_rule.template, captures)
        end

        def rules
          @rules ||= load_rules!
        end

        def reset!
          @rules = nil
        end

        private

        def match_rule(uri, rule)
          return unless uri.host == rule.host

          captures = match_path(uri.path, rule.path_segments)
          return unless captures

          params = extract_params(uri, rule.params)
          return unless params

          captures.merge!(params)

          return unless satisfies_matches?(captures, rule.matches)

          captures
        end

        def match_path(path, rule_segments)
          return unless path.start_with?('/')

          actual_segments = path[1..].split('/')
          return unless actual_segments.length >= rule_segments.length

          captures = {}

          rule_segments.zip(actual_segments) do |rule_seg, actual_seg|
            if rule_seg.start_with?('{') && rule_seg.end_with?('}')
              name = rule_seg[1..-2]
              captures[name] = Addressable::URI.unencode_component(actual_seg)
            elsif rule_seg != actual_seg
              # Match failure.
              captures = nil
              break
            end
          end

          captures
        end

        def extract_params(uri, rule_params)
          return {} if rule_params.empty?

          query_values = uri.query_values
          return unless query_values

          rule_params.each_with_object({}) do |name, hash|
            break nil unless query_values.key?(name)

            hash[name] = query_values[name]
          end
        end

        def satisfies_matches?(captures, rule_matches)
          rule_matches.all? do |capture_name, allowed_values|
            allowed_values.include?(captures[capture_name])
          end
        end

        def expand_template(template, captures)
          template.gsub(/\{(\w+)\}/) do
            value = captures[::Regexp.last_match(1)]
            if value
              # Percent-encode the replacement value; only leave "unreserved" ([a-zA-Z0-9._~-]) unencoded.
              Addressable::URI.encode_component(value, Addressable::URI::CharacterClasses::UNRESERVED)
            else
              # No match: leave completely unchanged.
              ::Regexp.last_match(0)
            end
          end
        end

        def load_config!
          YAML.safe_load_file(TRANSFORMS_PATH)
        end

        def load_rules!
          entries = load_config!

          entries.map do |entry|
            from = entry['from']
            raise "iframe_url_transforms.yml: rule missing 'from'" unless from.is_a?(Hash)
            raise "iframe_url_transforms.yml: rule missing 'from.host'" unless from['host'].present?
            raise "iframe_url_transforms.yml: rule missing 'from.path'" unless from['path'].present?
            raise "iframe_url_transforms.yml: rule missing 'to'" unless entry['to'].present?

            path = from['path']
            unless path.start_with?('/')
              raise "iframe_url_transforms.yml: 'from.path' must start with / (got #{path.inspect})"
            end

            Rule.new(
              host: from['host'],
              path_segments: path[1..].split('/'),
              params: Array(from['params']),
              matches: (from['match'] || {}).transform_values { |v| Array(v) },
              template: entry['to']
            )
          end
        end
      end
    end
  end
end
