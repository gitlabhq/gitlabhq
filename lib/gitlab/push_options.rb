# frozen_string_literal: true

module Gitlab
  class PushOptions
    VALID_OPTIONS = HashWithIndifferentAccess.new({
      merge_request: {
        keys: [:create, :merge_when_pipeline_succeeds, :target]
      },
      ci: {
        keys: [:skip]
      }
    }).freeze

    NAMESPACE_ALIASES = HashWithIndifferentAccess.new({
      mr: :merge_request
    }).freeze

    OPTION_MATCHER = /(?<namespace>[^\.]+)\.(?<key>[^=]+)=?(?<value>.*)/.freeze

    attr_reader :options

    def initialize(options = [])
      @options = parse_options(options)
    end

    def get(*args)
      options.dig(*args)
    end

    # Allow #to_json serialization
    def as_json(*_args)
      options
    end

    private

    def parse_options(raw_options)
      options = HashWithIndifferentAccess.new

      Array.wrap(raw_options).each do |option|
        namespace, key, value = parse_option(option)

        next if [namespace, key].any?(&:nil?)

        options[namespace] ||= HashWithIndifferentAccess.new
        options[namespace][key] = value
      end

      options
    end

    def parse_option(option)
      parts = OPTION_MATCHER.match(option)
      return unless parts

      namespace, key, value = parts.values_at(:namespace, :key, :value).map(&:strip)
      namespace = NAMESPACE_ALIASES[namespace] if NAMESPACE_ALIASES[namespace]
      value = value.presence || true

      return unless valid_option?(namespace, key)

      [namespace, key, value]
    end

    def valid_option?(namespace, key)
      keys = VALID_OPTIONS.dig(namespace, :keys)
      keys && keys.include?(key.to_sym)
    end
  end
end
