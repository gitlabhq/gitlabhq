# frozen_string_literal: true
module Gitlab
  module Graphql
    module Board
      class IssuesConnectionExtension < GraphQL::Schema::FieldExtension
        def after_resolve(value:, object:, context:, **rest)
          ::Boards::Issues::ListService
            .initialize_relative_positions(object.list.board, context[:current_user], value.nodes)

          value
        end
      end
    end
  end
end
