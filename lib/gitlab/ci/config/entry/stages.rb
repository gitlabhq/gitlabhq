# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration for pipeline stages.
        #
        class Stages < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          MAX_NESTING_LEVEL = 10

          validations do
            validates :config, nested_array_of_strings: { max_level: MAX_NESTING_LEVEL }
          end

          def self.default
            Config::EdgeStagesInjector.wrap_stages %w[build test deploy]
          end

          def value
            @config.flatten
          end
        end
      end
    end
  end
end
