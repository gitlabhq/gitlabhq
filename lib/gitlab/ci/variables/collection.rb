module Gitlab
  module Ci
    module Variables
      class Collection
        include Enumerable

        Variable = Struct.new(:key, :value, :public, :file)

        def initialize(variables = [])
          @variables = []

          variables.each { |variable| append(variable) }
        end

        def append(resource)
          @variables.append(fabricate(resource))
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

        def to_h
          self.map do |variable|
            variable.to_h.reject do |key, value|
              key == :file && value == false
            end
          end
        end

        alias_method :to_hash, :to_h

        private

        def fabricate(resource)
          case resource
          when Hash
            Variable.new(resource.fetch(:key),
                         resource.fetch(:value),
                         resource.fetch(:public, false),
                         resource.fetch(:file, false))
          when ::Ci::Variable
            Variable.new(resource.key, resource.value, false, false)
          when Collection::Variable
            resource.dup
          else
            raise ArgumentError, 'Unknown CI/CD variable resource!'
          end
        end
      end
    end
  end
end
