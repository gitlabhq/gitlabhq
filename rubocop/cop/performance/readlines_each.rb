# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      class ReadlinesEach < RuboCop::Cop::Cop
        MESSAGE = 'Avoid `IO.readlines.each`, since it reads contents into memory in full. ' \
          'Use `IO.each_line` or `IO.each` instead.'

        def_node_matcher :full_file_read_via_class?, <<~PATTERN
          (send
            (send (const nil? {:IO :File}) :readlines _) :each)
        PATTERN

        def_node_matcher :full_file_read_via_instance?, <<~PATTERN
          (... (... :readlines) :each)
        PATTERN

        def on_send(node)
          full_file_read_via_class?(node) { add_offense(node, location: :selector, message: MESSAGE) }
          full_file_read_via_instance?(node) { add_offense(node, location: :selector, message: MESSAGE) }
        end

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.loc.expression, node.source.gsub('readlines.each', 'each_line'))
          end
        end
      end
    end
  end
end
