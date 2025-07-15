# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # Checks for the usage of conditional statements (`if`, `unless`,
      # and ternary operators) in specs.
      #
      # Conditional logic in tests can obscure intent and introduce flakiness,
      # especially when used to check for the presence of elements or to guard
      # interactions. Instead of branching, prefer using expectations with
      # appropriate wait times or methods that include built-in waiting behavior.
      #
      # https://gitlab.com/gitlab-org/gitlab/-/issues/410138
      #
      # @example
      #
      #   # bad
      #
      #   page.has_css?('[data-testid="begin-commit-button"]') ? find('[data-testid="begin-commit-button"]').click : nil
      #
      #   if page.has_css?('[data-testid="begin-commit-button"]')
      #     find('[data-testid="begin-commit-button"]').click
      #   end
      #
      #   unless page.has_css?('[data-testid="other-button"]')
      #     skip "Button not available in this configuration"
      #   end
      #
      #   # good
      #
      #   # Use an expectation with appropriate wait time to ensure element presence
      #   expect(page).to have_css('[data-testid="begin-commit-button"]', wait: 10)
      #   find('[data-testid="begin-commit-button"]').click
      #
      #   # Or rely on `find`, which waits implicitly and fails fast if not found
      #   find('[data-testid="begin-commit-button"]').click
      #
      #   # For configuration-dependent elements, structure tests to avoid conditionals
      #   # by using separate test contexts or explicit expectations
      #   expect(page).to have_css('[data-testid="other-button"]')
      class AvoidConditionalStatements < RuboCop::Cop::Base
        MESSAGE = "Don't use `%{conditional}` conditional statement in specs, it might create flakiness. " \
                  "See https://gitlab.com/gitlab-org/gitlab/-/issues/385304#note_1345437109"

        def on_if(node)
          conditional = node.ternary? ? node.source : node.keyword

          add_offense(node, message: format(MESSAGE, conditional: conditional))
        end
      end
    end
  end
end
