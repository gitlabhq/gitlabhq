# frozen_string_literal: true

module RuboCop
  module Cop
    module UsageData
      # This cop checks that histogram method is not used in usage_data.rb files
      # for models representing large tables, as defined by migration helpers.
      #
      # @example
      #
      # # bad
      # histogram(Issue, buckets: 1..100)
      # histogram(User.active, buckets: 1..100)
      class HistogramWithLargeTable < RuboCop::Cop::Cop
        MSG = 'Avoid histogram method on %{model_name}'

        # Match one level const as Issue, Gitlab
        def_node_matcher :one_level_node, <<~PATTERN
          (send nil? :histogram
            `(const {nil? cbase} $_)
          ...)
        PATTERN

        # Match two level const as ::Clusters::Cluster, ::Ci::Pipeline
        def_node_matcher :two_level_node, <<~PATTERN
          (send nil? :histogram
            `(const
              (const {nil? cbase} $_)
            $_)
          ...)
        PATTERN

        def on_send(node)
          one_level_matches = one_level_node(node)
          two_level_matches = two_level_node(node)

          return unless Array(one_level_matches).any? || Array(two_level_matches).any?

          class_name = two_level_matches ? two_level_matches.join('::').to_sym : one_level_matches

          if large_table?(class_name)
            add_offense(node, location: :expression, message: format(MSG, model_name: class_name))
          end
        end

        private

        def large_table?(model)
          high_traffic_models.include?(model.to_s)
        end

        def high_traffic_models
          cop_config['HighTrafficModels'] || []
        end
      end
    end
  end
end
