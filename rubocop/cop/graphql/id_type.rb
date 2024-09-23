# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      class IDType < RuboCop::Cop::Base
        MSG_USE_STRING_FOR_IID = 'Do not use GraphQL::Types::ID for IIDs, use GraphQL::Types::String instead'
        MSG_USE_GLOBAL_ID = 'Do not use GraphQL::Types::ID, use a specific GlobalIDType instead'

        ALLOWLISTED_ARGUMENTS = %i[
          full_path project_path group_path target_project_path target_group_path target_path namespace_path
          context_namespace_path
        ].freeze

        def_node_matcher :iid_with_id?, <<~PATTERN
          (send nil? {:field :argument}
            (sym #iid?)
            (const (const (const nil? :GraphQL) :Types) :ID)
            (...)?)
        PATTERN

        def_node_search :graphql_id_allowed?, <<~PATTERN
          (send nil? :argument (_ #does_not_match?) (const (const (const nil? :GraphQL) :Types) :ID) ...)
        PATTERN

        def on_send(node)
          return add_offense(node, message: MSG_USE_STRING_FOR_IID) if iid_with_id?(node)
          return unless graphql_id_allowed?(node)

          add_offense(node, message: MSG_USE_GLOBAL_ID)
        end

        private

        def does_not_match?(arg_name)
          ALLOWLISTED_ARGUMENTS.exclude?(arg_name)
        end

        def iid?(arg_name)
          arg_name == :iid || arg_name.end_with?('_iid')
        end
      end
    end
  end
end
