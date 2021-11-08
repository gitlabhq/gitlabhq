# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class Base
        def self.enabled?(connection)
          raise NotImplementedError
        end

        def self.analyze(parsed)
          raise NotImplementedError
        end
      end
    end
  end
end
