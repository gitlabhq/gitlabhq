# frozen_string_literal: true

require_relative '../../qa_helpers'
require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module QA
      # This cop checks for the usage of data-qa-selectors or .qa-* classes in non-QA files
      #
      # @example
      #   # bad
      #   find('[data-qa-selector="the_selector"]')
      #   find('.qa-selector')
      #
      #   # good
      #   find('[data-testid="the_selector"]')
      #   find('#selector')
      class SelectorUsage < RuboCop::Cop::Base
        include QAHelpers
        include CodeReuseHelpers

        SELECTORS = /\.qa-\w+|data-qa-\w+/
        MESSAGE = %(Do not use `%s` as this is reserved for the end-to-end specs. Use a different selector or a data-testid instead.)

        def on_str(node)
          return if in_qa_file?(node)
          return unless in_spec?(node)

          add_offense(node, message: MESSAGE % node.value) if SELECTORS.match?(node.value)
        rescue StandardError
          # catch all errors and ignore them.
          # without this catch-all rescue, rubocop will fail
          # because of non-UTF-8 characters in some Strings
        end
      end
    end
  end
end
