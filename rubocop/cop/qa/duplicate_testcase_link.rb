# frozen_string_literal: true

module RuboCop
  module Cop
    module QA
      # This cop checks for duplicate testcase links across e2e specs
      #
      # @example
      #
      #   # bad
      #   it 'some test', testcase: '(...)/quality/test_cases/1892'
      #   it 'another test, testcase: '(...)/quality/test_cases/1892'
      #
      #   # good
      #   it 'some test', testcase: '(...)/quality/test_cases/1892'
      #   it 'another test, testcase: '(...)/quality/test_cases/1894'
      class DuplicateTestcaseLink < RuboCop::Cop::Cop
        MESSAGE = "Don't reuse the same testcase link in different tests. Replace one of `%s`."

        @testcase_set = Set.new

        def_node_matcher :duplicate_testcase_link, <<~PATTERN
          (block
            (send nil? ...
              ...
              (hash
                (pair
                  (sym :testcase)
                  (str $_))...)...)...)
        PATTERN

        def on_block(node)
          duplicate_testcase_link(node) do |link|
            break unless self.class.duplicate?(link)

            add_offense(node, message: MESSAGE % link)
          end
        end

        def self.duplicate?(link)
          !@testcase_set.add?(link)
        end
      end
    end
  end
end
