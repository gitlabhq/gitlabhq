# frozen_string_literal: true

module Gitlab
  class PushOptions
    VALID_OPTIONS = HashWithIndifferentAccess.new({
      merge_request: {
        keys: [
          :assign,
          :create,
          :description,
          :draft,
          :label,
          :merge_when_pipeline_succeeds,
          :milestone,
          :remove_source_branch,
          :squash,
          :target,
          :target_project,
          :title,
          :unassign,
          :unlabel
        ]
      },
      ci: {
        keys: [:skip, :variable]
      },
      integrations: {
        keys: [:skip_ci]
      },
      secret_detection: {
        keys: [:skip_all]
      },
      secret_push_protection: {
        keys: [:skip_all]
      }
    }).freeze

    MULTI_VALUE_OPTIONS = [
      %w[ci variable],
      %w[merge_request label],
      %w[merge_request unlabel],
      %w[merge_request assign],
      %w[merge_request unassign]
    ].freeze

    NAMESPACE_ALIASES = HashWithIndifferentAccess.new({
      mr: :merge_request
    }).freeze

    OPTION_MATCHER = Gitlab::UntrustedRegexp.new('(?<namespace>[^\.]+)\.(?<key>[^=]+)=?(?<value>.*)')

    CI_SKIP = 'ci.skip'

    attr_reader :options

    def initialize(options = [])
      @options = parse_options(options)
    end

    def get(...)
      options.dig(...)
    end

    # Allow #to_json serialization
    def as_json(*_args)
      options.as_json
    end

    private

    def parse_options(raw_options)
      options = HashWithIndifferentAccess.new

      Array.wrap(raw_options).each do |option|
        namespace, key, value = parse_option(option)

        next if [namespace, key].any?(&:nil?)

        store_option_info(options, namespace, key, value)
      end

      options
    end

    def store_option_info(options, namespace, key, value)
      options[namespace] ||= HashWithIndifferentAccess.new

      if option_multi_value?(namespace, key)
        options[namespace][key] ||= HashWithIndifferentAccess.new(0)
        options[namespace][key][value] += 1
      else
        options[namespace][key] = value
      end
    end

    def option_multi_value?(namespace, key)
      MULTI_VALUE_OPTIONS.any?([namespace, key])
    end

    def parse_option(option)
      parts = OPTION_MATCHER.match(option)
      return unless parts

      namespace = extract_match(parts, :namespace)
      key = extract_match(parts, :key)
      value = extract_match(parts, :value)

      namespace = NAMESPACE_ALIASES[namespace] if NAMESPACE_ALIASES[namespace]
      value = value.presence || true

      return unless valid_option?(namespace, key)

      [namespace, key, value]
    end

    def extract_match(parts, key)
      parts[key].to_s.strip
    end

    def valid_option?(namespace, key)
      keys = VALID_OPTIONS.dig(namespace, :keys)
      keys && keys.include?(key.to_sym)
    end
  end
end
