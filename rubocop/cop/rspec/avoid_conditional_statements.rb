# frozen_string_literal: true

require 'rubocop-rspec'

module RuboCop
  module Cop
    module RSpec
      # This cop checks for the usage of conditional statements in specs.
      #
      # https://gitlab.com/gitlab-org/gitlab/-/issues/410138
      #
      # @example
      #
      # # bad
      #
      #   page.has_css?('[data-testid="begin-commit-button"]') ? find('[data-testid="begin-commit-button"]').click : nil
      #
      #   if page.has_css?('[data-testid="begin-commit-button"]')
      #     find('[data-testid="begin-commit-button"]').click
      #   end
      #
      #   unless page.has_css?('[data-testid="begin-commit-button"]')
      #     find('[data-testid="begin-commit-button"]').click
      #   end
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
