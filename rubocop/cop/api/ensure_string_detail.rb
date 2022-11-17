# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      class EnsureStringDetail < RuboCop::Cop::Base
        include CodeReuseHelpers

        # This cop checks that API detail entries use Strings
        #
        # https://gitlab.com/gitlab-org/gitlab/-/issues/379037
        #
        # @example
        #
        # # bad
        # detail ['Foo bar baz bat', 'http://example.com']
        #
        # # good
        # detail 'Foo bar baz bat. http://example.com'
        #
        # end
        #
        MSG = 'Only String objects are permitted in API detail field.'

        def_node_matcher :detail_in_desc, <<~PATTERN
          (block
            (send nil? :desc ...)
            _args
            `(send nil? :detail $_ ...)
          )
        PATTERN

        RESTRICT_ON_SEND = %i[detail].freeze

        def on_send(node)
          return unless in_api?(node)

          parent = node.each_ancestor(:block).first
          detail_arg = detail_in_desc(parent)

          return unless detail_arg
          return if [:str, :dstr].include?(detail_arg.type)

          add_offense(node)
        end
      end
    end
  end
end
