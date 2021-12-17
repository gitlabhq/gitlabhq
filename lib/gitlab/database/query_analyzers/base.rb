# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class Base
        # `Exception` to ensure that is not easily rescued when running in test env
        QueryAnalyzerError = Class.new(Exception) # rubocop:disable Lint/InheritException

        def self.suppressed?
          Thread.current[self.suppress_key]
        end

        def self.requires_tracking?(parsed)
          false
        end

        def self.suppress=(value)
          Thread.current[self.suppress_key] = value
        end

        def self.with_suppressed(value = true, &blk)
          previous = self.suppressed?
          self.suppress = value
          yield
        ensure
          self.suppress = previous
        end

        def self.begin!
          Thread.current[self.context_key] = {}
        end

        def self.end!
          Thread.current[self.context_key] = nil
        end

        def self.context
          Thread.current[self.context_key]
        end

        def self.enabled?
          raise NotImplementedError
        end

        def self.analyze(parsed)
          raise NotImplementedError
        end

        def self.context_key
          "#{self.class.name}_context"
        end

        def self.suppress_key
          "#{self.class.name}_suppressed"
        end
      end
    end
  end
end
