# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Checks that `git` is not executed in a vendored gemspec file.
      # In some installed containers, `git` is not available.
      #
      # @example
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.test_files = `git ls-files -- test/*`.split("\n")
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.name = 'your_cool_gem_name'
      #     spec.test_files += Dir.glob('test/**/*')
      #   end
      #
      class AvoidExecutingGit < Base
        include RangeHelp

        MSG = 'Do not execute `git` in gemspec.'

        # @!method gem_specification(node)
        def_node_matcher :gem_specification, <<~PATTERN
          (block
            (send
              (const
                (const {cbase nil?} :Gem) :Specification) :new)
            ...)
        PATTERN

        def_node_matcher :send_node?, <<~PATTERN
          send
        PATTERN

        def_node_search :executes_string, <<~PATTERN
          $(xstr (str $_))
        PATTERN

        def on_block(block_node)
          return unless gem_specification(block_node)

          block_node.descendants.each do |node|
            next unless send_node?(node)

            str = executes_string(node)

            str.each do |execute_node, val|
              break unless val.start_with?('git ')

              add_offense(execute_node, message: message)
            end
          end
        end
      end
    end
  end
end
