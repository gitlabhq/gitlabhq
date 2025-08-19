# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Cop that encourages streaming file reading instead of reading the entire file into memory.
      # @example
      #   # bad
      #   File.readlines('some_file.txt').each do |line|
      #      process(line)
      #   end
      #
      #   # good
      #   File.each_line('some_file.txt') do |line|
      #      process(line)
      #   end
      class ReadlinesEach < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MESSAGE = 'Avoid `IO.readlines.each`, since it reads contents into memory in full. ' \
          'Use `IO.each_line` or `IO.each` instead.'

        # @!method full_file_read_via_class?(node)
        def_node_matcher :full_file_read_via_class?, <<~PATTERN
          (send
            (send (const nil? {:IO :File}) :readlines _) :each)
        PATTERN

        # @!method full_file_read_via_instance?(node)
        def_node_matcher :full_file_read_via_instance?, <<~PATTERN
          (... (... :readlines) :each)
        PATTERN

        def on_send(node)
          return unless full_file_read_via_class?(node) || full_file_read_via_instance?(node)

          add_offense(node.loc.selector, message: MESSAGE) do |corrector|
            corrector.replace(node.loc.expression, node.source.gsub('readlines.each', 'each_line'))
          end
        end
      end
    end
  end
end
