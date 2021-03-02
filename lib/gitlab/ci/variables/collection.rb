# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Collection
        include Enumerable

        attr_reader :errors

        def initialize(variables = [], errors = nil)
          @variables = []
          @variables_by_key = {}
          @errors = errors

          variables.each { |variable| self.append(variable) }
        end

        def append(resource)
          item = Collection::Item.fabricate(resource)
          @variables.append(item)
          @variables_by_key[item[:key]] = item

          self
        end

        def concat(resources)
          return self if resources.nil?

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

        def [](key)
          @variables_by_key[key]
        end

        def size
          @variables.size
        end

        def to_runner_variables
          self.map(&:to_runner_variable)
        end

        def to_hash
          self.to_runner_variables
            .to_h { |env| [env.fetch(:key), env.fetch(:value)] }
            .with_indifferent_access
        end

        def reject(&block)
          Collection.new(@variables.reject(&block))
        end

        # Returns a sorted Collection object, and sets errors property in case of an error
        def sorted_collection(project)
          Sort.new(self, project).collection
        end
      end
    end
  end
end
