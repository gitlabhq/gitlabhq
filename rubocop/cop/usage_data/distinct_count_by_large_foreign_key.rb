# frozen_string_literal: true

require_relative '../../usage_data_helpers'

module RuboCop
  module Cop
    module UsageData
      # Allows counts only for selected tables' foreign keys for `distinct_count` method.
      #
      # Because distinct_counts over large tables' foreign keys will take a long time
      #
      # @example
      #
      #   # bad because pipeline_id points to a large table
      #   distinct_count(Ci::Build, :commit_id)
      #
      class DistinctCountByLargeForeignKey < RuboCop::Cop::Base
        include UsageDataHelpers

        MSG = 'Avoid doing `%s` on foreign keys for large tables having above 100 million rows.'

        def_node_matcher :distinct_count?, <<-PATTERN
          (send _ $:distinct_count $...)
        PATTERN

        def on_send(node)
          return unless in_usage_data_file?(node)

          distinct_count?(node) do |method_name, method_arguments|
            next unless method_arguments && method_arguments.length >= 2
            next if batch_set_to_false?(method_arguments[2])
            next if allowed_foreign_key?(method_arguments[1])

            add_offense(node.loc.selector, message: format(MSG, method_name))
          end
        end

        private

        def allowed_foreign_key?(key)
          [:sym, :str].include?(key.type) && allowed_foreign_keys.include?(key.value.to_s)
        end

        def allowed_foreign_keys
          (cop_config['AllowedForeignKeys'] || []).map(&:to_s)
        end

        def batch_set_to_false?(options)
          return false unless options.is_a?(RuboCop::AST::HashNode)

          batch_set_to_false = false
          options.each_pair do |key, value|
            next unless value.boolean_type? && value.falsey_literal?
            next unless key.type == :sym && key.value == :batch

            batch_set_to_false = true
            break
          end

          batch_set_to_false
        end
      end
    end
  end
end
