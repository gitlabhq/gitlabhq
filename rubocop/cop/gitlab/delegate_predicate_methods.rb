# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # This cop looks for delegations to predicate methods with `allow_nil: true` option.
      # This construct results in three possible results: true, false and nil.
      # In other words, it does not preserve the strict Boolean nature of predicate method return value.
      # This cop suggests creating a method to handle `nil` delegator and ensure only Boolean type is returned.
      #
      # @example
      #   # bad
      #   delegate :is_foo?, to: :bar, allow_nil: true
      #
      #   # good
      #   def is_foo?
      #     return false unless bar
      #     bar.is_foo?
      #   end
      #
      #   def is_foo?
      #     !!bar&.is_foo?
      #   end
      class DelegatePredicateMethods < RuboCop::Cop::Base
        MSG = "Using `delegate` with `allow_nil` on the following predicate methods is discouraged: %s."
        RESTRICT_ON_SEND = %i[delegate].freeze
        def_node_matcher :predicate_allow_nil_option, <<~PATTERN
          (send nil? :delegate
            (sym $_)*
            (hash <$(pair (sym :allow_nil) true) ...>)
          )
        PATTERN

        def on_send(node)
          predicate_allow_nil_option(node) do |delegated_methods, _options|
            offensive_methods = delegated_methods.select { |method| method.end_with?('?') }
            next if offensive_methods.empty?

            add_offense(node, message: format(MSG, offensive_methods.join(', ')))
          end
        end
      end
    end
  end
end
