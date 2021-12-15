# frozen_string_literal: true

require_relative '../../qa_helpers'

module RuboCop
  module Cop
    module QA
      # This cop checks for correct format of testcase links across e2e specs
      #
      # @example
      #
      #   # bad
      #   it 'some test', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/557'
      #   it 'another test, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/2455'
      #
      #   # good
      #   it 'some test', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348312'
      #   it 'another test, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348236'
      class TestcaseLinkFormat < RuboCop::Cop::Cop
        include QAHelpers

        TESTCASE_FORMAT = %r{https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/\d+}.freeze
        MESSAGE = "Testcase link format incorrect. Please link a test case from the GitLab project. See: https://docs.gitlab.com/ee/development/testing_guide/end_to_end/best_practices.html#link-a-test-to-its-test-case."

        def_node_matcher :testcase_link_format, <<~PATTERN
          (block
            (send nil? ...
              ...
              (hash
                (pair
                  (sym :testcase)
                  (str $_))...)...)...)
        PATTERN

        def on_block(node)
          return unless in_qa_file?(node)

          testcase_link_format(node) do |link|
            add_offense(node, message: MESSAGE % link) unless TESTCASE_FORMAT =~ link
          end
        end
      end
    end
  end
end
