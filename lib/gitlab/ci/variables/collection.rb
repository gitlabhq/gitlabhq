module Gitlab
  module Ci
    module Variables
      class Collection
        include Enumerable

        def initialize(variables = [])
          @variables = []

          variables.each { |variable| self.append(variable) }
        end

        def append(resource)
          tap { @variables.append(Collection::Item.fabricate(resource)) }
        end

        def concat(resources)
          tap { resources.each { |variable| self.append(variable) } }
        end

        def each
          @variables.each { |variable| yield variable }
        end

        def +(other)
          self.class.new.tap do |collection|
            self.each { |variable| collection.append(variable) }
            other.each { |variable| collection.append(variable) }
          end
        end

        def to_runner_variables
          self.map(&:to_hash)
        end
      end
    end
  end
end
