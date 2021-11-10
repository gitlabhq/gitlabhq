# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class Base
        def self.begin!
          Thread.current[self.class.name] = {}
        end

        def self.end!
          Thread.current[self.class.name] = nil
        end

        def self.context
          Thread.current[self.class.name]
        end

        def self.enabled?
          raise NotImplementedError
        end

        def self.analyze(parsed)
          raise NotImplementedError
        end
      end
    end
  end
end
