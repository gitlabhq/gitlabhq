# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks define a valid summary
      #
      # @example
      #
      #   # bad (no summary given)
      #   desc do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success Entities::Environment
      #     ...
      #   end
      #
      #   # bad (summary too long and not concise)
      #   desc 'Get a specific environment. This feature was introduced in GitLab 18.2.'
      #         'It can be used with an active user account.' do
      #     detail ['Foo bar baz bat', 'http://example.com']
      #     success Entities::Environment
      #     ...
      #   end
      #
      #   # bad (summary is not a string)
      #   desc some_variable do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success Entities::Environment
      #   end
      #
      #   # good
      #   desc 'Get a specific environment' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success Entities::Environment
      #     ...
      #   end
      class DescriptionSummary < RuboCop::Cop::Base
        include CodeReuseHelpers

        MAX_SUMMARY_LENGTH = 120

        MSG_MISSING = 'API desc blocks must define a summary string. ' \
          'https://docs.gitlab.com/development/api_styleguide#defining-endpoint-desc'
        MSG_TOO_LONG = 'API desc summary must not exceed 120 characters. ' \
          'https://docs.gitlab.com/development/api_styleguide#defining-endpoint-desc'

        # @!method desc_with_summary(node)
        def_node_matcher :desc_with_summary, '(block (send nil? :desc ${str dstr}) ...)'

        def on_block(node)
          return unless node.method?(:desc)

          summary_node = desc_with_summary(node)

          if summary_node.nil?
            add_offense(node.send_node, message: MSG_MISSING)
            return
          end

          # The linter allows interpolated summaries but their length cannot measured accurately
          # As a result, all `summary_node.dstr_type?` are accepted.
          return unless summary_node.str_type?
          return if summary_node.value.length <= MAX_SUMMARY_LENGTH

          add_offense(summary_node, message: MSG_TOO_LONG)
        end

        alias_method :on_numblock, :on_block
      end
    end
  end
end
