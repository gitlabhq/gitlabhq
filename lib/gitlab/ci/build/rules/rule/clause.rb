# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause
        ##
        # Abstract class that defines an interface of a single
        # job rule specification.
        #
        # Used for job's inclusion rules configuration.
        #
        UnknownClauseError = Class.new(StandardError)

        def self.fabricate(type, value)
          type = type.to_s.camelize

          self.const_get(type).new(value) if self.const_defined?(type)
        end

        def initialize(spec)
          @spec = spec
        end

        def satisfied_by?(pipeline, seed = nil)
          raise NotImplementedError
        end
      end
    end
  end
end
