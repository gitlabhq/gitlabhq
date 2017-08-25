module Gitlab
  module Ci
    class Config
      module Entry
        class Simplifiable < SimpleDelegator
          EntryStrategy = Struct.new(:name, :condition)

          def initialize(config, **metadata)
            strategy = self.class.strategies.find do |variant|
              variant.condition.call(config)
            end

            entry = self.class.const_get(strategy.name)

            super(entry.new(config, metadata))
          end

          def self.strategy(name, **opts)
            EntryStrategy.new(name, opts.fetch(:if)).tap do |strategy|
              (@strategies ||= []).append(strategy)
            end
          end

          def self.strategies
            @strategies || []
          end
        end
      end
    end
  end
end
