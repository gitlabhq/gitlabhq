# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module QueryResult
        include Enumerable

        def each
          raise NotImplementedError
        end
      end
    end
  end
end
