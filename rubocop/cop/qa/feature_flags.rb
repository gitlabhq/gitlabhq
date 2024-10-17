# frozen_string_literal: true

require_relative '../../qa_helpers'

module RuboCop
  module Cop
    module QA
      # This cop checks for the usages of Runtime::Feature in QA specs and enforces
      # the presence and format of the `feature_flag` metadata.
      # @example
      #   # good
      #   describe 'some test', feature_flag: { name: :flag } do
      #
      #   # bad
      #   describe 'some test', :feature_flag do
      #
      #   # good
      #   describe 'some test', feature_flag: { name: :flag } do
      #     before do
      #       Runtime::Feature.enable(:flag)
      #
      #   # bad
      #   describe 'some test' do
      #     before do
      #       Runtime::Feature.enable(:flag)
      class FeatureFlags < RuboCop::Cop::Base
        APPLY_MESSAGE = "Apply the `feature_flag: { name: :flag }` metadata to the test to use `%{feature}` in " \
          "end-to-end tests."
        BLOCK_MESSAGE = "Feature flags must specify a name. Use a block with `feature_flag: { name: :flag }` instead."
        CONSTS = %w[Runtime::Feature QA::Runtime::Feature].freeze

        RSPEC_METHODS = %i[describe it context].freeze
        FEATURE_METHODS = %i[enable disable set enabled?].freeze
        RESTRICT_ON_SEND = RSPEC_METHODS + FEATURE_METHODS

        def_node_matcher :const_receiver, <<~PATTERN
          (send $const ...)
        PATTERN

        def_node_matcher :feature_flag_metatag?, <<~PATTERN
          (hash <(pair (sym :feature_flag) (hash <(pair (sym :name) _) ...>)) ...>)
        PATTERN

        def on_send(node)
          if FEATURE_METHODS.include?(node.method_name)
            return unless CONSTS.include?(const_receiver(node)&.const_name)
            return if has_required_metadata?(node)

            add_offense(node, message: format(APPLY_MESSAGE, feature: const_receiver(node).const_name))
          end

          return unless RSPEC_METHODS.include?(node.method_name)

          return unless has_feature_flag_metadata?(node)
          return if feature_flag_metatag?(node)

          add_offense(node, message: format(BLOCK_MESSAGE))
        end

        private

        def has_feature_flag_metadata?(node)
          node.arguments.any? { |arg| arg.sym_type? && arg.value == :feature_flag }
        end

        def has_required_metadata?(node)
          node.each_ancestor(:block).any? { |block| feature_flag_metatag?(block.send_node.last_argument) }
        end
      end
    end
  end
end
