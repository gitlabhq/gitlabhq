# frozen_string_literal: true

module RuboCop
  module Cop
    class StaticTranslationDefinition < RuboCop::Cop::Cop
      MSG = "The text you're translating will be already in the translated form when it's assigned to the constant. When a users changes the locale, these texts won't be translated again. Consider moving the translation logic to a method.".freeze

      TRANSLATION_METHODS = %i[_ s_ n_].freeze

      def_node_matcher :translation_method?, <<~PATTERN
      (send _ _ str*)
      PATTERN

      def_node_matcher :lambda_node?, <<~PATTERN
      (send _ :lambda)
      PATTERN

      def on_send(node)
        return unless translation_method?(node)

        method_name = node.children[1]
        return unless TRANSLATION_METHODS.include?(method_name)

        node.each_ancestor do |ancestor|
          receiver, _ = *ancestor
          break if lambda_node?(receiver) # translations defined in lambda nodes should be allowed

          if constant_assignment?(ancestor)
            add_offense(node, location: :expression)

            break
          end
        end
      end

      private

      def constant_assignment?(node)
        node.type == :casgn
      end
    end
  end
end
