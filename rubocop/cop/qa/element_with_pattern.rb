# frozen_string_literal: true

require_relative '../../qa_helpers'

module RuboCop
  module Cop
    module QA
      # This cop checks for the usage of patterns in QA elements
      #
      # @example
      #
      #   # bad
      #   element :some_element, "link_to 'something'"
      #   element :some_element, /link_to 'something'/
      #
      #   # good
      #   element :some_element
      #   element :some_element, required: true
      class ElementWithPattern < RuboCop::Cop::Cop
        include QAHelpers

        MESSAGE = "Don't use a pattern for element, create a corresponding `%s` instead.".freeze

        def on_send(node)
          return unless in_qa_file?(node)
          return unless method_name(node).to_s == 'element'

          element_name, *args = node.arguments

          return if args.first.nil?

          args.first.each_node(:str) do |arg|
            add_offense(arg, message: MESSAGE % "data-qa-selector=#{element_name.value}")
          end
        end

        private

        def method_name(node)
          node.children[1]
        end
      end
    end
  end
end
