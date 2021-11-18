# frozen_string_literal: true

module Gitlab
  module Webpack
    class GraphqlKnownOperations
      class << self
        include Gitlab::Utils::StrongMemoize

        def clear_memoization!
          clear_memoization(:graphql_known_operations)
        end

        def load
          strong_memoize(:graphql_known_operations) do
            data = ::Gitlab::Webpack::FileLoader.load("graphql_known_operations.yml")

            YAML.safe_load(data)
          rescue StandardError
            []
          end
        end
      end
    end
  end
end
