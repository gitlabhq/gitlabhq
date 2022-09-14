# frozen_string_literal: true

require_relative '../routes_under_scope'

module RuboCop
  module Cop
    # Checks for a project routes outside '/-/' scope.
    # For more information see: https://gitlab.com/gitlab-org/gitlab/issues/29572
    class PutProjectRoutesUnderScope < RuboCop::Cop::Base
      include RoutesUnderScope

      MSG = 'Put new project routes under /-/ scope'

      def_node_matcher :dash_scope?, <<~PATTERN
        (:send nil? :scope (:str "-"))
      PATTERN
    end
  end
end
