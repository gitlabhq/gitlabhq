# frozen_string_literal: true

module Ci
  module Inputs
    ##
    # Evaluates input rules to determine which options and default values should apply.
    # Finds the first rule that evaluates to `true` or uses the fallback rule.
    #
    #
    class RulesEvaluator
      include Gitlab::Utils::StrongMemoize

      RULE_EXPRESSION_STATEMENT = Gitlab::Ci::Pipeline::Expression::Statement
      RULE_EXPRESSION_KEY = :if

      def initialize(rules, current_inputs)
        @rules = rules || []
        @current_inputs = current_inputs || {}
      end

      def resolved_options
        matching_rule&.[](:options)
      end

      def resolved_default
        matching_rule&.[](:default)
      end

      private

      attr_reader :rules, :current_inputs

      def matching_rule
        rules.find { |rule| rule_matches?(rule) }
      end
      strong_memoize_attr :matching_rule

      def rule_matches?(rule)
        return true unless rule[RULE_EXPRESSION_KEY]

        evaluate_condition(rule[RULE_EXPRESSION_KEY])
      end

      def evaluate_condition(if_clause)
        RULE_EXPRESSION_STATEMENT.new(
          if_clause,
          inputs: current_inputs
        ).truthful?
      end
    end
  end
end
