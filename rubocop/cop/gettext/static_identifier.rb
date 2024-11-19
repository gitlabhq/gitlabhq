# frozen_string_literal: true

module RuboCop
  module Cop
    module Gettext
      # Ensure that gettext identifiers are statically defined and not
      # interpolated, formatted, or concatenated.
      #
      # @example
      #
      #   # bad
      #   _('Hi #{name}')
      #   _('Hi %{name}' % { name: 'Luki' })
      #   _(format('Hi %{name}', name: 'Luki'))
      #
      #   # good
      #   _('Hi %{name}') % { name: 'Luki' }
      #   format(_('Hi %{name}', name: 'Luki'))
      #
      #   # also good
      #   var = "Hi"
      #   _(var)
      #   _(some_method_call)
      #   _(CONST)
      class StaticIdentifier < RuboCop::Cop::Base
        MSG = 'Ensure to pass static strings to translation method `%{method_name}(...)`.'

        # Number of parameters to check for translation methods.
        PARAMETERS_TO_CHECK = {
          _: 1,
          s_: 1,
          N_: 1,
          n_: 2
        }.freeze

        # RuboCop-specific optimization for `on_send`.
        RESTRICT_ON_SEND = PARAMETERS_TO_CHECK.keys.freeze

        DENIED_METHOD_CALLS = %i[% format + concat].freeze

        def on_send(node)
          method_name = node.method_name
          arguments = node.arguments

          each_invalid_argument(method_name, arguments) do |argument_node|
            message = format(MSG, method_name: method_name)

            add_offense(argument_node || node, message: message)
          end
        end

        private

        def each_invalid_argument(method_name, argument_nodes)
          number = PARAMETERS_TO_CHECK.fetch(method_name)

          argument_nodes.take(number).each do |argument_node|
            yield argument_node unless valid_argument?(argument_node)
          end
        end

        def valid_argument?(node)
          return false unless node

          basic_type?(node) || multiline_string?(node) || allowed_method_call?(node)
        end

        def basic_type?(node)
          node.str_type? || node.lvar_type? || node.const_type?
        end

        def multiline_string?(node)
          node.dstr_type? && node.children.all?(&:str_type?)
        end

        def allowed_method_call?(node)
          return false unless node.send_type?

          !DENIED_METHOD_CALLS.include?(node.method_name)
        end
      end
    end
  end
end
