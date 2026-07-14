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
        ParseError = Class.new(StandardError)

        # Per-match timeout (seconds) passed to Regexp.new. Bounds a single path match.
        REGEXP_TIMEOUT_SECONDS = 0.05

        # Total time budget (seconds) for evaluating one rule's regexp across all paths.
        REGEXP_TOTAL_TIMEOUT_SECONDS = 2

        # Max regexp length, re-checked at runtime on the expanded pattern since
        # variable expansion can grow it past the config-time limit.
        REGEXP_MAX_LENGTH = 255

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
