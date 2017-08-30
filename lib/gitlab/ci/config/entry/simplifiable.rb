module Gitlab
  module Ci
    class Config
      module Entry
        class Simplifiable < SimpleDelegator
          EntryStrategy = Struct.new(:name, :condition)

          def initialize(config, **metadata)
            unless self.class.const_defined?(:UnknownStrategy)
              raise ArgumentError, 'UndefinedStrategy not available!'
            end

            strategy = self.class.strategies.find do |variant|
              variant.condition.call(config)
            end

            entry = self.class.entry_class(strategy)

            super(entry.new(config, metadata))
          end

          def self.strategy(name, **opts)
            EntryStrategy.new(name, opts.fetch(:if)).tap do |strategy|
              strategies.append(strategy)
            end
          end

          def self.strategies
            @strategies ||= []
          end

          def self.entry_class(strategy)
            if strategy.present?
              self.const_get(strategy.name)
            else
              self::UnknownStrategy
            end
          end
        end
      end
    end
  end
end
