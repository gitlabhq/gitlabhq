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

        ##
        # If `file: true` has been provided we expose it, otherwise we
        # don't expose `file` attribute at all (stems from what the runner
        # expects).
        #
        def to_runner_variables
          self.map do |variable|
            variable.to_h.reject do |component, value|
              component == :file && value == false
            end
          end
        end

        private

        def fabricate(resource)
          case resource
          when Hash
            Collection::Variable.new(resource.fetch(:key),
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
