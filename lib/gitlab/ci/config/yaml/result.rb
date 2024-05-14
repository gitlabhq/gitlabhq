# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Result
          attr_reader :error, :error_class

          def initialize(config: nil, error: nil, error_class: nil, interpolated: false)
            @config = Array.wrap(config)
            @error = error
            @error_class = error_class
            @interpolated = interpolated
          end

          def valid?
            error.nil?
          end

          def interpolated?
            !!@interpolated
          end

          def has_header?
            return false unless @config.first.is_a?(Hash)

            @config.size > 1 && @config.first.key?(:spec)
          end

          def header
            raise ArgumentError unless has_header?

            @config.first
          end

          def content
            return @config.last if has_header?

            @config.first || {}
          end

          def spec
            (has_header? && header[:spec]) || {}
          end
        end
      end
    end
  end
end
