# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      class IDType < RuboCop::Cop::Base
        MSG = 'Do not use GraphQL::Types::ID, use a specific GlobalIDType instead'

        ALLOWLISTED_ARGUMENTS = %i[
          iid full_path project_path group_path target_project_path target_group_path target_path namespace_path
          context_namespace_path
        ].freeze

        def_node_search :graphql_id_type?, <<~PATTERN
          (send nil? :argument (_ #does_not_match?) (const (const (const nil? :GraphQL) :Types) :ID) ...)
        PATTERN

        def on_send(node)
          return unless graphql_id_type?(node)

          add_offense(node)
        end

        private

        def does_not_match?(arg)
          !ALLOWLISTED_ARGUMENTS.include?(arg) # rubocop:disable Rails/NegateInclude
        end
      end
    end
  end
end
