# frozen_string_literal: true

require_relative '../routes_under_scope'

module RuboCop
  module Cop
    # Checks for a group routes outside '/-/' scope.
    # For more information see: https://gitlab.com/gitlab-org/gitlab/issues/29572
    class PutGroupRoutesUnderScope < RuboCop::Cop::Base
      include RoutesUnderScope

      MSG = 'Put new group routes under /-/ scope'

      def_node_matcher :dash_scope?, <<~PATTERN
        (:send nil? :scope (hash <(pair (sym :path)(str "groups/*group_id/-")) ...>))
      PATTERN
    end
  end
end
