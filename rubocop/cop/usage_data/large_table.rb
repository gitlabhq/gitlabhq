# frozen_string_literal: true

require_relative '../../usage_data_helpers'

module RuboCop
  module Cop
    module UsageData
      class LargeTable < RuboCop::Cop::Base
        include UsageDataHelpers

        # This cop checks that batch count and distinct_count are used in usage_data.rb files in metrics based on ActiveRecord models.
        #
        # @example
        #
        # # bad
        # Issue.count
        # List.assignee.count
        # ::Ci::Pipeline.auto_devops_source.count
        # ZoomMeeting.distinct.count(:issue_id)
        #
        # # Good
        # count(Issue)
        # count(List.assignee)
        # count(::Ci::Pipeline.auto_devops_source)
        # distinct_count(ZoomMeeting, :issue_id)
        MSG = 'Use one of the %{count_methods} methods for counting on %{class_name}'

        # Match one level const as Issue, Gitlab
        def_node_matcher :one_level_node, <<~PATTERN
          (send
            (const {nil? cbase} $...)
          $...)
        PATTERN

        # Match two level const as ::Clusters::Cluster, ::Ci::Pipeline
        def_node_matcher :two_level_node, <<~PATTERN
          (send
            (const
              (const {nil? cbase} $...)
            $...)
          $...)
        PATTERN

        def on_send(node)
          return unless in_usage_data_file?(node)

          one_level_matches = one_level_node(node)
          two_level_matches = two_level_node(node)

          return unless Array(one_level_matches).any? || Array(two_level_matches).any?

          if one_level_matches
            class_name = one_level_matches[0].first
            method_used = one_level_matches[1]&.first
          else
            class_name = "#{two_level_matches[0].first}::#{two_level_matches[1].first}".to_sym
            method_used = two_level_matches[2]&.first
          end

          return if non_related?(class_name) || allowed_methods.include?(method_used)

          counters_used = node.ancestors.any? { |ancestor| allowed_method?(ancestor) }

          unless counters_used
            add_offense(node, message: format(MSG, count_methods: count_methods.join(', '), class_name: class_name))
          end
        end

        private

        def count_methods
          cop_config['CountMethods'] || []
        end

        def allowed_methods
          cop_config['AllowedMethods'] || []
        end

        def non_related_classes
          cop_config['NonRelatedClasses'] || []
        end

        def non_related?(class_name)
          non_related_classes.include?(class_name)
        end

        def allowed_method?(ancestor)
          ancestor.send_type? && !ancestor.dot? && count_methods.include?(ancestor.method_name)
        end
      end
    end
  end
end
