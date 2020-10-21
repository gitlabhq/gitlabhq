# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      class IDType < RuboCop::Cop::Cop
        MSG = 'Do not use GraphQL::ID_TYPE, use a specific GlobalIDType instead'

        WHITELISTED_ARGUMENTS = %i[iid full_path project_path group_path target_project_path].freeze

        def_node_search :graphql_id_type?, <<~PATTERN
          (send nil? :argument (_ #does_not_match?) (const (const nil? :GraphQL) :ID_TYPE) ...)
        PATTERN

        def on_send(node)
          return unless graphql_id_type?(node)

          add_offense(node)
        end

        private

        def does_not_match?(arg)
          !WHITELISTED_ARGUMENTS.include?(arg)
        end
      end
    end
  end
end
