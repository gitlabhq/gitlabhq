# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that denylists the use of ".becomes(SomeConstant)".
    #
    # The use of becomes() will result in a new object being created, throwing
    # away any eager loaded assocations. This in turn can cause N+1 query
    # problems, even when a developer eager loaded all necessary associations.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/23182 for more information.
    class AvoidBecomes < RuboCop::Cop::Base
      MSG = 'Avoid the use of becomes(SomeConstant), as this creates a ' \
        'new object and throws away any eager loaded associations. ' \
        'When creating URLs in views, just use the path helpers directly. ' \
        'For example, instead of `link_to(..., [group.becomes(Namespace), ...])` ' \
        'use `link_to(..., namespace_foo_path(group, ...))`. Most of the time there is no ' \
        'need to pass in namespace to the path helpers after implementaton of ' \
        'https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12566'

      def_node_matcher :becomes?, <<~PATTERN
        (send {send ivar lvar} :becomes ...)
      PATTERN

      def on_send(node)
        add_offense(node) if becomes?(node)
      end
    end
  end
end
