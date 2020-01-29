# frozen_string_literal: true
module Gitlab
  module Graphql
    module Extensions
      class ExternallyPaginatedArrayExtension < GraphQL::Schema::Field::ConnectionExtension
        def resolve(object:, arguments:, context:)
          yield(object, arguments)
        end
      end
    end
  end
end
