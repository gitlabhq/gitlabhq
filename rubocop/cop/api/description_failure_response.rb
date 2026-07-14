# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks define at least one failure response
      #
      # @example
      #
      #   # bad
      #   desc 'Get a specific thing' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success Entities::Thing
      #     tags ['things']
      #     ...
      #   end
      #
      #   # good
      #   desc 'Get a specific thing' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success Entities::Thing
      #     failure [{ code: 404, message: 'Not found' }]
      #     tags ['things']
      #     ...
      #   end
      class DescriptionFailureResponse < RuboCop::Cop::Base
        include CodeReuseHelpers

        MSG = 'API desc blocks must define a failure response. https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-failures.'

        # @!method has_failure_response?(node)
        def_node_matcher :has_failure_response?, '`(send nil? :failure ...)'

        def on_block(node)
          return unless node.method?(:desc)
          return if has_failure_response?(node)

          add_offense(node)
        end

        alias_method :on_numblock, :on_block
      end
    end
  end
end
