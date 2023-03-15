# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Yaml
        class Result
          attr_reader :error

          def initialize(config: nil, error: nil)
            @config = Array.wrap(config)
            @error = error
          end

          def valid?
            error.nil?
          end

          def has_header?
            @config.size > 1
          end

          def header
            raise ArgumentError unless has_header?

            @config.first
          end

          def content
            @config.last
          end
        end
      end
    end
  end
end
