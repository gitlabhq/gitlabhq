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
          "#{self}::#{type.to_s.camelize}".safe_constantize&.new(value)
        end

        def initialize(spec)
          @spec = spec
        end

        def satisfied_by?(pipeline, context = nil)
          raise NotImplementedError
        end
      end
    end
  end
end
