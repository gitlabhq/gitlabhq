# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Detects the use of `.keys.first` or `.values.first` and suggests a
      # change to `.each_key.first` or `.each_value.first`. This reduces
      # memory usage and execution time.
      #
      # @example
      #
      # # bad
      #
      # hash.keys.first
      # hash.values.first
      #
      # # good
      #
      # hash.each_key.first
      # hash.each_value.first
      #
      class KeysFirstAndValuesFirst < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = 'Prefer `.%{autocorrect_method}.first` over `.%{current_method}.first`. ' \
          'This reduces memory usage and execution time.'

        AUTOCORRECT_METHOD = {
          keys: 'each_key',
          values: 'each_value'
        }.freeze

        def_node_matcher :keys_or_values_first, <<~PATTERN
          (send (send ({send const hash lvar} ...) ${:keys :values}) :first)
        PATTERN

        def on_send(node)
          current_method = keys_or_values_first(node)
          return unless current_method

          autocorrect_method = AUTOCORRECT_METHOD.fetch(current_method)
          msg = format(MSG, autocorrect_method: autocorrect_method, current_method: current_method)

          add_offense(node.loc.selector, message: msg) do |corrector|
            replacement = "#{autocorrect_expression(node)}.#{autocorrect_method}.first"
            corrector.replace(node, replacement)
          end
        end

        private

        def autocorrect_expression(node)
          node.receiver.receiver.source
        end
      end
    end
  end
end
