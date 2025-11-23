# frozen_string_literal: true

module RuboCop
  module APIHiddenParamHelpers
    extend RuboCop::AST::NodePattern::Macros
    # Use with REST API param linters
    # determines if param is hidden
    # @!method hidden_param?(node)
    def_node_matcher :hidden_param?, <<~PATTERN
      (send _
        ...
        (hash <(pair (sym :documentation) (hash <(pair (sym :hidden) (true))>)) ...>)
      )
    PATTERN
  end
end
