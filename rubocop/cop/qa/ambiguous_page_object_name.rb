# frozen_string_literal: true

require_relative '../../qa_helpers'

module RuboCop
  module Cop
    module QA
      # This cop checks for the usage of the ambiguous name "page"
      #
      # @example
      #
      #   # bad
      #   Page::Object.perform do |page| do ...
      #   Page::Another.perform { |page| ... }
      #
      #   # good
      #   Page::Object.perform do |object| do ...
      #   Page::Another.perform { |another| ... }
      class AmbiguousPageObjectName < RuboCop::Cop::Base
        include QAHelpers

        MESSAGE = "Don't use 'page' as a name for a Page Object. Use `%s` instead."

        def_node_matcher :ambiguous_page?, <<~PATTERN
          (block
            (send
              (const ...) :perform)
            (args
              (arg :page)) ...)
        PATTERN

        def on_block(node)
          return unless in_qa_file?(node)
          return unless ambiguous_page?(node)

          add_offense(node.arguments.each_node(:arg).first,
            message: MESSAGE % page_object_name(node))
        end

        private

        def page_object_name(node)
          node.send_node.children[-2].const_name.downcase.split('::').last
        end
      end
    end
  end
end
