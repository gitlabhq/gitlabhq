# frozen_string_literal: true

module Gitlab
  module Ci
    module Tags
      class BulkInsert
        class ConfigurationFactory
          def initialize(record)
            @record = record
          end

          def build
            strategy.build_from(@record)
          end

          private

          def strategy
            strategies.find(proc { NoConfig }) do |strategy|
              strategy.applies_to?(@record)
            end
          end

          def strategies
            [
              BuildsTagsConfiguration,
              RunnerTaggingsConfiguration
            ]
          end
        end
      end
    end
  end
end
