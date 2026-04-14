# frozen_string_literal: true

module RuboCop
  module Cop
    module Gettext
      # Ensure that gettext methods are called with the correct number of parameters.
      # `_()` and `s_()` accept exactly 1 parameter.
      # `n_()` accepts exactly 3 parameters.
      #
      # @example
      #
      #   # bad
      #   _('Hello', 'extra')
      #   s_('Namespace|Hello', 'extra')
      #   n_('Apple', 'Apples')
      #   n_('Apple', 'Apples', count, 'extra')
      #
      #   # good
      #   _('Hello')
      #   s_('Namespace|Hello')
      #   n_('Apple', 'Apples', count)
      #
      class ParameterCount < RuboCop::Cop::Base
        MSG_SINGULAR = 'The `%{method_name}(...)` method accepts exactly 1 parameter, but got %{count}.'
        MSG_PLURAL = 'The `%{method_name}(...)` method accepts exactly 3 parameters, but got %{count}.'

        RESTRICT_ON_SEND = %i[_ s_ n_].freeze

        EXACT_ONE = %i[_ s_].freeze

        def on_send(node)
          method_name = node.method_name
          count = node.arguments.size

          if EXACT_ONE.include?(method_name) && count != 1
            add_offense(node, message: format(MSG_SINGULAR, method_name: method_name, count: count))
          elsif method_name == :n_ && count != 3
            add_offense(node, message: format(MSG_PLURAL, method_name: method_name, count: count))
          end
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
