# frozen_string_literal: true

module RuboCop
  module Cop
    module Graphql
      # Forbids the use of `loads:` in GraphQL argument definitions.
      # Using `loads:` leaks information about resource existence because
      # it returns different error messages for "not found" vs "not authorized".
      #
      # @example
      #
      #   # bad
      #   argument :milestone_id, ::Types::GlobalIDType[::Milestone], loads: Types::MilestoneType
      #
      #   # good
      #   argument :milestone_id, ::Types::GlobalIDType[::Milestone]
      #
      #   def resolve(milestone_id:)
      #     milestone = authorized_find!(id: milestone_id)
      #   end
      class ForbiddenLoadsArgument < RuboCop::Cop::Base
        MSG = "Do not use `loads:` in GraphQL arguments. " \
          "It leaks information about resource existence. " \
          "Instead, accept the ID and load/authorize the object manually in the resolver. " \
          "See https://docs.gitlab.com/ee/development/graphql_guide/authorization.html"

        RESTRICT_ON_SEND = [:argument].freeze

        # @!method argument_with_loads?(node)
        def_node_matcher :argument_with_loads?, <<~PATTERN
          (send nil? :argument ... (hash <(pair (sym :loads) _) ...>))
        PATTERN

        def on_send(node)
          return unless argument_with_loads?(node)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
