# frozen_string_literal: true

module Gitlab
  module Graphql
    class Lazy
      # Force evaluation of a (possibly) lazy value
      def self.force(value)
        case value
        when ::BatchLoader::GraphQL
          value.sync
        when ::Concurrent::Promise
          value.execute.value
        else
          value
        end
      end
    end
  end
end
