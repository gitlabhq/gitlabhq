# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      class Normalizer
        class Factory
          include Gitlab::Utils::StrongMemoize

          def initialize(name, config)
            @name = name
            @config = config
          end

          def create
            return [] unless strategy

            strategy.build_from(@name, @config)
          end

          private

          def strategy
            strong_memoize(:strategy) do
              strategies.find do |strategy|
                strategy.applies_to?(@config)
              end
            end
          end

          def strategies
            [NumberStrategy, MatrixStrategy]
          end
        end
      end
    end
  end
end
