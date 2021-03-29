# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that checks for correct calling of #feature_available?
      class FeatureAvailableUsage < RuboCop::Cop::Cop
        OBSERVED_METHOD = :feature_available?
        LICENSED_FEATURE_LITERAL_ARG_MSG = '`feature_available?` should not be called for features that can be licensed (`%s` given), use `licensed_feature_available?(feature)` instead.'
        LICENSED_FEATURE_DYNAMIC_ARG_MSG = "`feature_available?` should not be called for features that can be licensed (`%s` isn't a literal so we cannot say if it's legit or not), using `licensed_feature_available?(feature)` may be more appropriate."
        NOT_ENOUGH_ARGS_MSG = '`feature_available?` should be called with two arguments: `feature` and `user`.'
        FEATURES = %i[
          issues
          forking
          merge_requests
          wiki
          snippets
          builds
          repository
          pages
          metrics_dashboard
          analytics
          operations
          security_and_compliance
          container_registry
        ].freeze
        EE_FEATURES = %i[requirements].freeze
        ALL_FEATURES = (FEATURES + EE_FEATURES).freeze
        SPECIAL_CLASS = %w[License].freeze

        def on_send(node)
          return unless method_name(node) == OBSERVED_METHOD
          return if caller_is_special_case?(node)
          return if feature_name(node).nil?
          return if ALL_FEATURES.include?(feature_name(node)) && args_count(node) == 2

          if !ALL_FEATURES.include?(feature_name(node))
            add_offense(node, location: :expression, message: licensed_feature_message(node))
          elsif args_count(node) < 2
            add_offense(node, location: :expression, message: NOT_ENOUGH_ARGS_MSG)
          end
        end

        def licensed_feature_message(node)
          message_template = dynamic_feature?(node) ? LICENSED_FEATURE_DYNAMIC_ARG_MSG : LICENSED_FEATURE_LITERAL_ARG_MSG

          message_template % feature_arg_name(node)
        end

        private

        def method_name(node)
          node.children[1]
        end

        def class_caller(node)
          node.children[0]&.const_name.to_s
        end

        def caller_is_special_case?(node)
          SPECIAL_CLASS.include?(class_caller(node))
        end

        def feature_arg(node)
          node.children[2]
        end

        def dynamic_feature?(node)
          feature = feature_arg(node)
          return false unless feature

          !feature.literal?
        end

        def feature_name(node)
          feature = feature_arg(node)
          return unless feature
          return feature.children.compact.join('.') if dynamic_feature?(node)
          return feature.value if feature.respond_to?(:value)

          feature.type
        end

        def feature_arg_name(node)
          feature = feature_arg(node)
          return unless feature
          return feature.children.compact.join('.') if dynamic_feature?(node)
          return feature.children[0].inspect if feature.literal?

          feature.type
        end

        def args_count(node)
          node.children[2..].size
        end
      end
    end
  end
end
